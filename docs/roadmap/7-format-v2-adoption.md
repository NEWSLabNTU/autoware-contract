# Phase 7: Manifest Format v2 Adoption

Adopt new manifest format features from play_launch Phase 33 in the
Autoware contract manifests.

Depends on: play_launch Phase 33 (complete).

## Work Items

### 7.1: Add arg types to manifests

- [x] `control.yaml` — added `type: bool` to 4 launch flags
  (`launch_control_validator`, `launch_autonomous_emergency_braking`,
  `launch_lane_departure_checker`, `launch_collision_detector`)
- [x] Other manifests audited — only control.yaml has boolean launch flags
  (other args are free strings: topic names, paths, modes)
- [x] Satisfiability check: control.yaml's controller always publishes
  on both topics, so all 16 bool combinations are variant-complete

### 7.2: Migrate to unified scope interface

- [x] All 36 manifests already use `sub:`/`pub:` (migrated in Phase 33.2)
- [x] Added scope-level `srv:` / `cli:` groups to 9 manifests:
  - `mission_planner.yaml` — `srv:` (3 route services) + `cli:` (route_selector proxy)
  - `mrm_handler.yaml` — `cli:` (3 MRM operator services, cross-scope)
  - `mrm_comfortable_stop_operator.yaml` — `srv:` (operate)
  - `mrm_emergency_stop_operator.yaml` — `srv:` (operate)
  - `pose_initializer.yaml` — `srv:` (initialize)
  - `simple_planning_simulator.yaml` — `srv:` (control_mode_request, set_pose)
  - `vehicle_door_simulator.yaml` — `srv:` (doors_command, doors_layout)
  - `aggregator.yaml` — `srv:` (reset, set_initializing)
  - `external_cmd_selector.yaml` — `srv:` (select_external_command)

### 7.3: Add missing args after parser fix

- [x] `behavior_planning.yaml` — re-added `input_traffic_light_topic_name`
  and `input_vector_map_topic_name` (now in scope.args after parser fix 33.1)
- [x] Audited all manifests — only behavior_planning had skipped args

### 7.4: Satisfiability validation

- [x] control.yaml has `type: bool` on 4 launch flags (16 configs)
- [x] Variant-complete: controller_node_exe always publishes on both topics
  (unconditional), so no bool combination creates dangling entities
- [x] Added `just check-sat` recipe to justfile
