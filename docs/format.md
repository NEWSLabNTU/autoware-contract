# Manifest Format (Autoware Overlay)

The manifest format itself is specified upstream in
[play_launch's launch-manifest spec](https://github.com/NEWSLabNTU/play_launch/blob/main/src/ros-launch-manifest/docs/launch-manifest.md).
That document is authoritative — read it for the full grammar, evaluation
semantics, QoS model, satisfiability rules, and example diagnostics. This
page only covers the conventions specific to authoring contracts in this
repository.

## Package Layout

```
<package_name>/<stem>.yaml
```

Each manifest corresponds to one Autoware launch file. `<stem>` is the
launch file name with `.launch.xml` or `.launch.py` stripped. For example:

- `tier4_control_launch/control.yaml` ← `control.launch.xml`
- `tier4_planning_launch/motion_planning.yaml` ← `motion_planning.launch.xml`

Scopes without entities (pass-through includes, parameter loaders) don't
need manifest files — they are silently skipped by the checker.

## Source-Traceability Comments

Every requirement should cite its source in an inline `#` comment — source
file path + line number, launch XML remap, or QoS constructor call:

```yaml
nodes:
  controller_node_exe:
    sub:
      trajectory:                    # /planning/trajectory — remap ~/input/reference_trajectory
        min_rate_hz: 10              # driven by upstream planner at 10 Hz
      operation_mode:                # /system/operation_mode/state — QoS(1).transient_local()
        state: true                  # InterProcessPollingSubscriber in controller_node.cpp:118
        required: true
```

The goal is that any manifest line can be re-derived from the cited source
without re-reading the original launch file.

## Refinement Stages

Manifests are authored incrementally. Each stage adds a layer of detail:

| Stage    | What to add                                                                |
|----------|----------------------------------------------------------------------------|
| Skeleton | Nodes + paths (from launch entity list)                                    |
| Topics   | Actual remapped topic names + message types (from launch XML)              |
| QoS      | reliability, durability, depth (from `create_publisher`/`create_subscription`) |
| Rates    | `min_rate_hz`, `max_rate_hz` (from timers, config params)                  |
| Timing   | `max_latency_ms`, `max_age_ms` (from CARET measurements or design specs)   |
| Services | `srv:` / `cli:` on nodes + `services:` at scope level                      |

Per-package status is tracked in [status.md](status.md).

## Static Validation Rules (Summary)

The checker runs 15 rules. The full descriptions, severities, and example
diagnostics live in the upstream spec's
[Static Validation](https://github.com/NEWSLabNTU/play_launch/blob/main/src/ros-launch-manifest/docs/launch-manifest.md#static-validation)
section; the table below is a quick index for authors.

| Rule              | What it catches                                                           |
|-------------------|---------------------------------------------------------------------------|
| `endpoint-unique` | Duplicate endpoint names within a node                                     |
| `wiring`          | Path endpoints not connected by any topic                                  |
| `qos-compat`      | Invalid QoS values                                                         |
| `qos-match`       | Publisher/subscriber QoS incompatible per DDS offered ≥ requested rule     |
| `rate-hierarchy`  | Publisher rate < topic rate < subscriber rate                              |
| `rate-chain`      | Output rate unachievable from upstream                                     |
| `budget-overflow` | Descendant budget exceeds ancestor budget (part > whole)                   |
| `scope-budget`    | Sum of children exceeds scope budget                                       |
| `causal-dag`      | Cycles in the dataflow graph (`state:` breaks cycles)                      |
| `drop-sanity`     | Scope drop rate tighter than child topic; delivery rate < `sub.min_rate_hz` |
| `service-wiring`  | Service client with no matching server across tree                         |
| `service-type`    | Service with no type; server/client not on node                            |
| `dangling-entity` | Topic with 0 publishers / service or action with 0 servers across tree     |
| `satisfiability`  | Arg combination produces dangling entities or unreachable nodes (Z3)       |
| `consistency`     | Same resolved topic/service has conflicting `type:`, `rate_hz:`, or topic-level `qos:` |
