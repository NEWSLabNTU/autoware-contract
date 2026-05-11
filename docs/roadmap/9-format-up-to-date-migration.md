# Phase 9: Manifest Format Up-to-Date Migration

Bring every manifest in this repo into compliance with the current
play_launch manifest format. The repo was last aligned with format v2
(Phase 7) which predates Issues #33, #34, #35, #41, #44, #45, #49 in
play_launch. The format has since converged on a flat **topics + nodes
+ services** model with ROS topic names as keys; the older "scope
interface" / `imports`/`exports` / scope-level `sub:`/`pub:`/`srv:`/
`cli:` patterns have been removed.

Depends on: play_launch Phase 35 (manifest format redesign, complete).

Authoritative spec: `play_launch/src/ros-launch-manifest/docs/launch-manifest.md`.

## Goals

1. Every leaf manifest validates standalone with `play_launch check`.
2. Every intermediate manifest contributes only `includes:` and
   scope-level `paths:` (E2E contracts), never a scope interface.
3. The full tree (`autoware_launch/planning_simulator.launch.xml`)
   validates with zero errors. Warnings categorized and triaged.
4. Optional features (`lifecycle:`, `max_transport_ms`,
   per-endpoint `qos:` overrides) are added where sources support them.

## Background — Why Migrate

The pre-#33 format had two parallel ways to express cross-scope wiring:

- **Topic block** with relative keys (e.g. `control_cmd`) — channel-level.
- **Scope interface** (`imports:`/`exports:` or scope-level
  `sub:`/`pub:`/`srv:`/`cli:` groups, plus group-name refs in
  `paths.input/output`) — boundary-level.

The two had to be kept consistent by hand and the checker had no good
way to reconcile them. Issue #33 unified the model: topic keys are
**ROS topic names** (relative or absolute) and the checker merges
declarations by FQN across scopes. The scope interface became dead
code; #41 extended the same pattern to services. #34 + #35 redefined
scope-level paths to use topic-name input/output (not group names).

## Migration Items

### 9.1 Drop scope-level `sub:`/`pub:`/`srv:`/`cli:` blocks (53 files)

Spec: `launch-manifest.md` §Manifest Elements ("scope interface
removed") + Issue #33 / #41.

Affected: 53 of 67 manifests. Includes nearly every leaf manifest and
all `tier4_*_launch/*.yaml` orchestrators.

Before:
```yaml
nodes:
  controller_node_exe:
    sub: { trajectory: { min_rate_hz: 10 } }
    pub: { control_cmd: { min_rate_hz: 30 } }

sub:
  trajectory_input:
    - controller_node_exe/trajectory
pub:
  control_output:
    - controller_node_exe/control_cmd
```

After:
```yaml
nodes:
  controller_node_exe:
    sub: { trajectory: { min_rate_hz: 10 } }
    pub: { control_cmd: { min_rate_hz: 30 } }

topics:
  /planning/trajectory:
    type: autoware_planning_msgs/msg/Trajectory
    sub: [controller_node_exe/trajectory]
  /control/command/control_cmd:
    type: autoware_control_msgs/msg/Control
    pub: [controller_node_exe/control_cmd]
```

Notes:
- **No `imports:`/`exports:`** in the new format. Scope boundaries
  flow through `topics:` and `services:` declarations using ROS names.
- **Cross-scope merge by FQN**: relative keys are resolved against the
  scope namespace; absolute keys (`/...`) cross subsystems unchanged.
  Each scope only references its own nodes in `pub:`/`sub:` lists.

### 9.2 Topic keys = ROS topic names (all `topics:` blocks)

Spec: `launch-manifest.md` §Topic Name Resolution.

Current `topics:` blocks (6 files) use scope-local aliases like
`control_cmd`, `predicted_trajectory`. Migrate to ROS names:

- **Relative** for within-subsystem topics (resolved via scope ns):
  `command/control_cmd`, `lateral/predicted_trajectory`.
- **Absolute** for cross-subsystem topics: `/planning/trajectory`,
  `/localization/kinematic_state`, `/map/vector_map`.

Per-spec data on Autoware 1.5.0 (182 topics): ~81% relative, ~19%
absolute. Capture mode (`play_launch run --save-manifest-dir`) can
generate the resolved names automatically as a starting point.

### 9.3 Migrate scope-level `paths:` to topic-name I/O (#34)

Before:
```yaml
paths:
  control:
    input: trajectory_input        # group name
    output: [control_output]
```

After:
```yaml
paths:
  control:
    input: /planning/trajectory
    output: [/control/command/control_cmd]
```

The checker traces dataflow between the named topics within the
declaring scope's subtree. When parent and child declare paths with
the same resolved (input, output) topics, `budget-overflow` checks
child budget ≤ parent budget.

### 9.4 Migrate node-level `paths:` (audit only)

Node paths still use endpoint names (not topics) — same as before. But
audit each file: ensure `input:` / `output:` reference endpoint names
defined on the **same node**, not group-aliases that no longer exist
after 9.1. Likely surfaces dangling refs once `wiring` runs.

### 9.5 Move `max_age_ms` to subscriber endpoints (#23)

Previously `max_age_ms` could appear on scope paths. Spec moved it to
**subscriber endpoints** — it is now a freshness constraint at the
point of consumption, runtime-checked via the interception layer.
Audit `paths:` blocks; relocate `max_age_ms` to the consuming sub
endpoint:

Before:
```yaml
paths:
  control:
    input: /planning/trajectory
    output: [/control/command/control_cmd]
    max_age_ms: 200
```

After:
```yaml
nodes:
  controller_node_exe:
    sub:
      trajectory:
        min_rate_hz: 10
        max_age_ms: 200            # consumer-side freshness budget
```

### 9.6 Update `docs/format.md`

Currently documents removed features (`imports:`/`exports:`, scope
interface, group-name path refs, 5 endpoint properties). Replace with
a thin Autoware-specific page that links to upstream:

```markdown
# Manifest Format

The manifest format is specified in [play_launch's launch-manifest spec](
https://github.com/NEWSLabNTU/play_launch/blob/main/src/ros-launch-manifest/docs/launch-manifest.md).

This page lists Autoware-specific authoring conventions on top of the
upstream format.
```

Then keep only Autoware-specific items: source-traceability comment
convention, refinement-stage table, package layout `<pkg>/<stem>.yaml`.

### 9.7 Update README.md rule list and stats

- "9 static rules" → 15 rules.
- New rules to mention: `qos-match`, `dangling-entity`,
  `satisfiability`, `consistency`, `service-type`, `service-wiring`.
- Renamed: `drop-rate` → `drop-sanity`.
- Update coverage stats once Phase 4 re-run on migrated manifests.

### 9.8 Re-run end-to-end check, fix `consistency` errors

After 9.1–9.5 land, run `just check` and triage new diagnostics:
- `consistency`: same topic declared in multiple scopes with
  conflicting `type:`/`rate_hz:`/topic-level `qos:`.
- `wiring`: path endpoints not connected by any topic.
- `dangling-entity`: 0-publisher topics across the tree.

Expect a wave of `consistency` errors during transition because each
scope now has to declare the topic with full `type:` (required field)
for standalone validity. Resolve by either (a) declaring the topic in
every scope that touches it (with matching `type:`) or (b) for
cross-subsystem topics that are inputs only, declaring the topic with
`sub: [...]` (no `pub:`) — the producer's manifest declares `pub:`.

## Optional Items (after core migration)

These are spec features that improve coverage but are not required for
the manifests to validate.

### 9.9 Lifecycle nodes (#49)

Add `lifecycle: true` on every managed node. Autoware uses lifecycle
nodes in localization, sensing, and some perception components.
Runtime monitors gate rate/latency/age checks on the node being in
the `Active` state.

Candidates (initial sweep — verify against source):
- `autoware_pose_initializer` (lifecycle for initialize service)
- `autoware_map_projection_loader`
- Any sensor driver wrapped via `LifecycleNode` in
  `autoware_sensing_launch`

Out of scope for v1 (per spec): per-state contracts, activation
ordering. Just the Boolean flag.

### 9.10 `max_transport_ms` and per-subscriber overrides (#44)

Spec: `launch-manifest.md` §Latency and Data Freshness, §Topics.

Add topic-level `max_transport_ms` for known cross-machine /
cross-network hops. Override per subscriber when a single ROS topic
fans out to subs with very different transports:

```yaml
topics:
  /perception/objects:
    type: autoware_perception_msgs/msg/PredictedObjects
    pub: [prediction/objects]
    sub: [planning/objects, debug_recorder/objects]
    max_transport_ms: 5            # default

nodes:
  planning:
    sub:
      objects:
        max_transport_ms: 0        # intra-process collocation
  debug_recorder:
    sub:
      objects:
        # inherits 5ms default
```

The per-sub override changes the edge weight in scope-path
critical-path computation (`latency = max_pred(pred + edge.transport)
+ node.processing`).

### 9.11 Per-endpoint `qos:` overrides (#45)

Spec: `launch-manifest.md` §Quality of Service.

Where a topic has subscribers that legitimately disagree with the
publisher's QoS (e.g. a logger forced to `reliable` on a
`best_effort` sensor stream), declare the override on the endpoint:

```yaml
topics:
  /sensor/pointcloud:
    type: sensor_msgs/msg/PointCloud2
    pub: [lidar_driver/output]
    sub: [perception/input, logger/input]
    qos: { reliability: best_effort, depth: 5 }

nodes:
  logger:
    sub:
      input:
        qos: { reliability: reliable }    # override → qos-match error if pub stays best_effort
```

Source code is the truth: grep `create_publisher` /
`create_subscription` calls for QoS arguments and reflect divergence
in the manifest. The new `qos-match` rule catches DDS incompatibility
(`offered ≥ requested` on `reliability` and `durability`).

### 9.12 Service-side `max_response_ms`

Phase 1 was on hold pending traceable sources. Reopen: add
`max_response_ms` on srv endpoints where Autoware documents response
budgets (MRM operators, pose initializer, scenario selector). Skip
where unspecified.

### 9.13 Args satisfiability sweep (#7.4 follow-up)

`control.yaml` already has `type: bool` on 4 launch flags. Sweep the
rest of the tree: add `type: bool` to any arg that gates an `if:`
condition. Add `choices: [...]` for selector args
(`localization_mode`, `pose_source`, etc.). Re-run `just check-sat`.

## Phase Order

```
9.1  drop scope interface ──────┬──→ 9.8  re-check
9.2  topic keys = ROS names ────┤
9.3  scope path I/O migration ──┤
9.4  node path audit ───────────┤
9.5  max_age_ms relocation ─────┘

9.6  docs/format.md  (anytime, independent)
9.7  README          (anytime, independent)

9.9  lifecycle      (after 9.8 clean)
9.10 max_transport_ms (after 9.8 clean)
9.11 endpoint qos   (after 9.8 clean)
9.12 service contracts (after 9.8 clean — reopens Phase 1)
9.13 args satisfiability sweep (after 9.8 clean)
```

9.1–9.5 are mechanical and must land together — partial migration
leaves the repo unparseable. Easiest path is one PR per
package/subsystem, each PR migrating both the leaf manifest and any
intermediate manifest in the same package.

9.6 and 9.7 are doc-only and can land first as a signal of intent.

9.8 is the gate: zero-error build on the migrated tree before
optional items.

## Validation

After each migration PR:

```bash
just check                    # zero errors expected
just check-sat                # variant-complete on bool/choices args
play_launch check --rule consistency --manifest-dir . \
    autoware_launch planning_simulator.launch.xml \
    map_path:=/tmp/dummy_map  # focus on cross-scope agreement
```

Track per-package status in `docs/status.md`. Replace the existing
"Skel/Topics/QoS/Rates/Timing/Svcs/ScoSvc/Args/Cond/Valid" columns
with a simpler post-migration set: **Topics(ROS)**, **Paths(ROS)**,
**No-ScopeIf**, **Lifecycle**, **Transport**, **EpQoS**, **Valid**.

## Migration Template

A canonical migrated leaf manifest for reference (write during 9.1):

`autoware_mrm_comfortable_stop_operator/mrm_comfortable_stop_operator.yaml`
— small surface area, has both pub-only and srv endpoints, currently
uses every deprecated pattern (scope-level `pub:`/`srv:`). Migrating
this first produces a worked example for the rest of the repo.

## Tracking

Open one issue per work item (9.1 through 9.13) in this repo. Link
each to the corresponding play_launch design issue (#33, #34, #41,
#44, #45, #49) for traceability.

## Status

- **9.1–9.5: Complete.** Post-migration `just check` reports 0 errors,
  193 warnings. Scope-interface blocks dropped, topic keys use ROS
  names, scope/node paths migrated, `max_age_ms` relocated to
  subscriber endpoints.
- **9.6: Complete** (this task). `docs/format.md` rewritten as a thin
  Autoware overlay that links to the upstream spec.
- **9.7: Complete** (this task). README rule list updated to the 15
  current rules; "9 static validation rules" wording bumped.
- **9.8: Complete.** Zero-error build verified against the migrated
  tree.
- **9.9 Lifecycle nodes: No-op for planning_simulator.** A survey of
  `~/repos/autoware/1.5.0-ws/src/universe/autoware_universe/` and
  `/opt/autoware/1.5.0/share/` finds no `LifecycleNode` derivations
  or `<lifecycle_node>` launch tags in any package included by
  `planning_simulator.launch.xml`. The only lifecycle nodes in 1.5.0
  are in `ros2_socketcan` and `boost_serial_driver` (real-vehicle
  stack only). Reopen if a future Autoware release introduces
  lifecycle in the simulator stack.
- **9.10 `max_transport_ms`: Deferred — needs runtime measurement.**
  planning_simulator runs intra-process / SHM on one machine;
  transport latencies are sub-millisecond and not reliably
  author-time-knowable. Add only after capture-mode measurements via
  the rcl_interception layer. Cross-machine deployments would benefit
  immediately; pure simulator runs gain little.
- **9.11 Per-endpoint `qos:` overrides: Selective — handled inline.**
  Topic-level `qos:` blocks were added in 21 files (67 new blocks total)
  where source-traceability comments document the profile (e.g.
  `# QoS(1).transient_local()`, `# best_effort`). Skipped: topics with
  `type: TODO/msg/TODO` placeholders, topics already declaring `qos:`,
  and topics whose comments only describe semantics (`polling`,
  `state: true`) without a concrete profile. No `qos-match` errors
  surfaced after the pass. Per-endpoint divergence is rare in Autoware
  — add overrides only when source-code divergence is confirmed.
- **9.12 Service `max_response_ms`: Deferred — Phase 1 still on hold.**
  All current `srv:` comments document "no documented response time
  requirement". Reopen with concrete budgets when Autoware design
  docs publish them.
- **9.13 Args satisfiability sweep: Already complete.** All 10
  launch-gating args (`launch_*`, `use_*`) used in `if:` / `unless:`
  conditions across the tree have `type: bool` declared. Verified:

  ```bash
  for arg in launch_autonomous_emergency_braking launch_collision_detector \
             launch_control_validator launch_default_adapi launch_dummy_doors \
             launch_dummy_vehicle launch_lane_departure_checker \
             launch_remaining_distance_time_calculator \
             use_control_command_gate use_traffic_light_recognition; do
    grep -A1 "^  $arg:" -r . --include="*.yaml" | grep "type: bool"
  done
  ```

  Returns one match per arg. Selector args (`pose_source`, etc.) —
  none currently in this repo.

### Final Stats

| Metric | Value |
|--------|-------|
| Manifest files in repo | 67 |
| Manifest files loaded by checker | 62 (5 scopes have no manifest) |
| Errors after migration | 0 |
| Warnings after migration | 193 |
| Files with deprecated scope-level `sub:`/`pub:`/`srv:`/`cli:` | 0 (was 53) |
| `max_age_ms` on scope paths | 0 (was 2 — relocated to subs) |
| Topic-level `qos:` blocks added | 67 across 21 files |

**Warning breakdown:** 190 `dangling-entity` (topics with 0 publishers
or 0 subscribers across the merged tree, mostly TODO type placeholders
or unwired sides) + 3 `service-wiring` (mrm_handler clients triaged
as known gap pending real-vehicle stack).

**Files changed:** 56 (per `git diff --stat`), +1435 / −783 lines.
