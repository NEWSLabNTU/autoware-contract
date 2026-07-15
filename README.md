# Autoware Communication Contracts

Topic manifest files describing the expected communication graph for
[Autoware](https://github.com/autowarefoundation/autoware) — topics, services,
QoS settings, rate constraints, and timing budgets per launch file.

These contracts enable **static verification** of Autoware's inter-node
communication without running the system. Errors like QoS mismatches, rate
hierarchy violations, missing wiring, infeasible drop budgets, and causal
cycles are caught at authoring time.

## Quick Start

```bash
# Install play_launch (the checker tool)
pip install play_launch

# Check contracts against Autoware planning_simulator
play_launch check --contracts . \
    autoware_launch planning_simulator.launch.xml

# With launch arguments
play_launch check --contracts . \
    autoware_launch planning_simulator.launch.xml \
    vehicle_model:=sample_vehicle sensor_model:=sample_sensor_kit
```

The checker parses the launch file to build the scope table (which launch file
includes which, under what namespace), loads manifest files for each scope,
applies namespace prefixes, and runs 15 static validation rules with
source-annotated diagnostics.

This repository is a **user overlay**: point `--contracts <dir>` at a checkout
of this repo to supply contracts for packages that ship none of their own.
play_launch resolves contracts per scope in overlay → provider sidecar →
legacy order, so this repo only fills coverage gaps rather than replacing
contracts a package already ships.

## Repository Layout

```
<package_name>/launch/<stem>.contract.yaml
```

Each manifest corresponds to one Autoware launch file. `<stem>` is the launch
file name with `.launch.xml` or `.launch.py` stripped. For example:

- `tier4_control_launch/launch/control.contract.yaml` ← `control.launch.xml`
- `tier4_planning_launch/launch/motion_planning.contract.yaml` ← `motion_planning.launch.xml`

Scopes without entities (pass-through includes, parameter loaders) don't need
manifest files — they are silently skipped by the checker.

## Manifest Format

Each manifest is a YAML file describing the nodes, topics, services, and
timing contracts for a single launch file scope. See [docs/format.md](docs/format.md)
for the full specification.

Quick example:

```yaml
version: 1

nodes:
  controller_node_exe:
    sub:
      trajectory:                    # /planning/trajectory — QoS(1)
        min_rate_hz: 10
      kinematic_state:               # /localization/kinematic_state
        state: true                  # polled, not causal
    pub:
      control_cmd:                   # QoS(1).transient_local()
        min_rate_hz: 30
    paths:
      main:
        input: trajectory
        output: [control_cmd]
        max_latency_ms: 10

topics:
  control_cmd:
    type: autoware_control_msgs/msg/Control
    pub: [controller_node_exe/control_cmd]
    sub: [control_validator/control_cmd]
    rate_hz: 30
    qos:
      reliability: reliable
      durability: transient_local
      depth: 1
```

## What Gets Checked

The checker runs 15 static validation rules. See the
[upstream spec](https://github.com/NEWSLabNTU/play_launch/blob/main/src/ros-launch-manifest/docs/launch-manifest.md#static-validation)
for full descriptions, severities, and example diagnostics.

| Rule | What it catches |
|------|----------------|
| **endpoint-unique** | Duplicate endpoint names within a node |
| **wiring** | Path endpoints not connected by any topic |
| **qos-compat** | Invalid QoS values |
| **qos-match** | Publisher/subscriber QoS incompatible per DDS offered ≥ requested rule |
| **rate-hierarchy** | Publisher rate < topic rate < subscriber rate |
| **rate-chain** | Output rate unachievable from upstream |
| **budget-overflow** | Descendant budget exceeds ancestor budget (part > whole) |
| **scope-budget** | Sum of children exceeds scope budget |
| **causal-dag** | Cycles in the dataflow graph (`state:` breaks cycles) |
| **drop-sanity** | Scope drop rate tighter than child topic; delivery rate < subscriber demand |
| **service-wiring** | Service client with no matching server across tree |
| **service-type** | Service with no type; server/client not on node |
| **dangling-entity** | Topic with 0 publishers / service or action with 0 servers across tree |
| **satisfiability** | Arg combination produces dangling entities or unreachable nodes (Z3) |
| **consistency** | Same resolved topic/service has conflicting `type:`, `rate_hz:`, or topic-level `qos:` across scopes |

## Autoware Version

Autoware Universe **1.5.0**. Contracts are authored from source code in
`~/repos/autoware/1.5.0-ws/` and installed binaries in `/opt/autoware/1.5.0/`.

## Coverage

36 manifests covering all launch file scopes with entities in
`planning_simulator.launch.xml` (119 entities across 48 packages).
See [docs/status.md](docs/status.md) for per-file status and
[docs/roadmap/](docs/roadmap/) for upcoming work items.

## Contributing

### Authoring Practices

- **Source traceability**: every requirement must cite its origin in an inline
  `#` comment — source file path, launch XML remap, QoS constructor call.
- **Design notes**: issues discovered during authoring go in
  [docs/notes.md](docs/notes.md) and feed back into the manifest format design.

### Refinement Stages

| Stage | What to add |
|-------|-------------|
| Skeleton | Nodes, imports/exports, paths (from launch entity list) |
| Topics | Actual remapped topic names + message types (from launch XML) |
| QoS | reliability, durability, depth (from source `create_publisher`/`create_subscription`) |
| Rates | `min_rate_hz`, `max_rate_hz` (from timers, config params) |
| Timing | `max_latency_ms`, `max_age_ms` (from CARET measurements or design specs) |
| Services | `srv:` / `cli:` on nodes + `services:` at scope level |

## License

Apache-2.0
