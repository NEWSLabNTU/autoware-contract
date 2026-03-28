# Phase 3: Conditions

Add `if:` and `unless:` to nodes and topics that are conditionally loaded
based on launch arguments. Mirrors `if="$(var x)"` in launch XML.

Depends on Phase 2 (args must be declared before conditions can reference them).

## Criteria

- Every conditionally-loaded **node** in the launch file has a matching `if:` or
  `unless:` in the manifest
- Condition expressions use `$(var ...)` referencing args from Phase 2
- Plugin-level flags (modules inside a single node) are documented in arg
  comments but do NOT get `if:` — see Note 7 in `docs/notes.md`

## Work Items

### 3.1: Control — conditional checker nodes

`control.launch.xml` conditionally loads 4 checker nodes via `<group if="...">`:

- [x] `control.yaml` — add `if:` on 4 nodes:
  - `control_validator` — `if: $(var launch_control_validator)` (line 231)
  - `autonomous_emergency_braking` — `if: $(var launch_autonomous_emergency_braking)` (line 247)
  - `lane_departure_checker` — `if: $(var launch_lane_departure_checker)` (line 214)
  - `collision_detector` — `if: $(var launch_collision_detector)` (line 263)
- [x] Add 4 new args for the launch flags

### ~~3.2: Motion planning modules~~ — Not applicable

Module flags (`launch_obstacle_stop_module`, etc.) control plugins loaded
inside `motion_velocity_planner`, not separate nodes. The node always exists.
See Note 7. No `if:` needed.

### ~~3.3: Behavior planning modules~~ — Not applicable

Same as 3.2 — behavior path/velocity planner modules are plugins, not nodes.

### ~~3.4: Control gate variant~~ — Not applicable

`use_control_command_gate` selects a plugin class, not a node. Documented
in args comment only.

### ~~3.5: Simulator output mode~~ — Not applicable

`motion_publish_mode` changes which output topics the simulator publishes,
but the node always exists. No `if:` needed — document in args comment.

## Design Note

Most Autoware "conditional" features are plugin-level, not node-level.
Only `control.launch.xml` has real conditional `<group if="...">` blocks
that include/exclude entire composable nodes. The `if:`/`unless:` manifest
feature is most valuable for these true conditional nodes.
