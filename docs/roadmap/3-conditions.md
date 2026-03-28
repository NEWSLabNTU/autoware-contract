# Phase 3: Conditions

Add `if:` and `unless:` to nodes and topics that are conditionally loaded
based on launch arguments. Mirrors `if="$(var x)"` in launch XML.

Depends on Phase 2 (args must be declared before conditions can reference them).

## Criteria

- Every conditionally-loaded node in the launch file has a matching `if:` or
  `unless:` in the manifest
- Condition expressions use `$(var ...)` referencing args from Phase 2
- When checked with different arg sets, the right entities are included/excluded

## Work Items

### 3.1: Motion planning modules

`motion_planning.launch.xml` conditionally enables velocity planner modules:

- [ ] `motion_planning.yaml` — add conditions for velocity planner modules:
  ```yaml
  args:
    launch_obstacle_stop_module: "true"
    launch_obstacle_cruise_module: "true"
    launch_out_of_lane_module: "true"
    # ... other module flags
  ```
  (Note: currently all modules are baked into one `motion_velocity_planner` node.
  Conditions apply to the module list parameter, not separate nodes. May need
  to model as a single node with variable behavior rather than conditional nodes.)

### 3.2: Behavior planning modules

- [ ] `behavior_planning.yaml` — similar module flags for behavior path/velocity
  planner modules

### 3.3: Control gate variant

- [ ] `control.yaml` — `use_control_command_gate` selects plugin variant:
  ```yaml
  # This affects which plugin is loaded, not which node exists.
  # May not need if:/unless: — just document in comments.
  ```

### 3.4: Simulator output mode

- [ ] `simple_planning_simulator.yaml` — `motion_publish_mode` changes which
  output topics are active
