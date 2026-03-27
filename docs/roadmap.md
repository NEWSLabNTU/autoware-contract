# Roadmap

**Status**: Complete (36 manifests, all refined with source traceability)
**Autoware version**: Universe 1.5.0
**Target launch**: `autoware_launch planning_simulator.launch.xml`

---

## Scope Inventory

Autoware planning_simulator has **83 launch file scopes** across **48 packages**.
Only **36** scopes have entities (nodes/containers/composable nodes).
The remaining 47 are pass-through includes or parameter loaders that don't
need manifest files.

---

## Refinement Stages

| Stage | What to add | Source |
|-------|-------------|--------|
| Skeleton | Nodes, imports/exports, paths | `record.json` entity list |
| Topics | Remapped topic names + message types | Launch XML `<remap>` tags |
| QoS | reliability, durability, depth | Source `create_publisher`/`create_subscription` |
| Rates | `min_rate_hz`, `max_rate_hz` | Source timers, config params |
| Timing | `max_latency_ms`, `max_age_ms` | CARET measurements, design specs |
| Services | `srv:` / `cli:` on nodes, `services:` at scope | Source `create_service`/`create_client` |

---

## Service Documentation

| Manifest | Node | Services | Done |
|----------|------|----------|------|
| `mission_planner.yaml` | mission_planner | clear_route, set_lanelet_route, set_waypoint_route | [x] |
| `mission_planner.yaml` | route_selector | clear_route, set_lanelet_route, set_waypoint_route (clients) | [x] |
| `mrm_comfortable_stop_operator.yaml` | mrm_comfortable_stop_operator | operate (OperateMrm) | [x] |
| `mrm_emergency_stop_operator.yaml` | mrm_emergency_stop_operator | operate (OperateMrm) | [x] |
| `mrm_handler.yaml` | mrm_handler | 3 clients: pull_over/comfortable/emergency operate | [x] |
| `aggregator.yaml` | aggregator_node | reset, set_initializing | [x] |
| `control.yaml` | autonomous_emergency_braking | none (confirmed from source) | [x] |
| `pose_initializer.yaml` | pose_initializer | initialize (localization::Initialize) | [x] |
| `vehicle_door_simulator.yaml` | vehicle_door_simulator | doors/command, doors/layout | [x] |
| `simple_planning_simulator.yaml` | simple_planning_simulator | control_mode_request, set_pose | [x] |
| `default_adapi.yaml` | ADAPI nodes | deferred (19 nodes, services documented upstream) | n/a |

---

## Per-Subsystem Status

### Control (7 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `tier4_control_launch/control.launch.xml` | 5 | [x] | [x] | [x] | [x] | [x] |
| `autoware_external_cmd_converter/external_cmd_converter.launch.py` | 1 | [x] | [x] | [x] | n/a | [x] |
| `autoware_external_cmd_selector/external_cmd_selector.launch.py` | 1 | [x] | [x] | [x] | n/a | n/a |

Pass-through (no entities):
- `autoware_launch/tier4_control_component.launch.xml`
- `autoware_control_evaluator/control_evaluator.launch.xml`

### Planning — Mission (6 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `autoware_mission_planner_universe/mission_planner.launch.xml` | 4 | [x] | [x] | [x] | [x] | [x] |
| `autoware_mission_planner_universe/goal_pose_visualizer.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |
| `autoware_manual_lane_change_handler/manual_lane_change_handler.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |

### Planning — Behavior (4 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `tier4_planning_launch/behavior_planning.launch.xml` | 4 | [x] | [x] | [x] | [x] | [x] |

### Planning — Motion (5 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `tier4_planning_launch/motion_planning.launch.xml` | 5 | [x] | [x] | [x] | [x] | [x] |

### Planning — Scenario (3+1 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `autoware_scenario_selector/scenario_selector.launch.xml` | 1 | [x] | [x] | [x] | [x] | [x] |
| `autoware_external_velocity_limit_selector/external_velocity_limit_selector.launch.xml` | 1 | [x] | [x] | [x] | n/a | n/a |
| `autoware_hazard_lights_selector/hazard_lights_selector.launch.xml` | 1 | [x] | [x] | [x] | n/a | n/a |
| `autoware_remaining_distance_time_calculator/remaining_distance_time_calculator.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |

### Perception — Prediction & Tracking (2 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `autoware_map_based_prediction/map_based_prediction.launch.xml` | 1 | [x] | [x] | [x] | [x] | [x] |
| `autoware_multi_object_tracker/multi_object_tracker.launch.xml` | 1 | [x] | [x] | [x] | [x] | [x] |

### Perception — Occupancy Grid (2 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `autoware_probabilistic_occupancy_grid_map/laserscan_based_occupancy_grid_map.launch.py` | 2 | [x] | [x] | [x] | n/a | [x] |

### Map (1 entity)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `autoware_map_projection_loader/map_projection_loader.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |

### System (24 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `autoware_topic_state_monitor/load_topic_state_monitor.launch.xml` | 10 (×10) | [x] | [x] | n/a | n/a | n/a |
| `autoware_topic_state_monitor/load_topic_state_monitor_tf.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |
| `autoware_component_state_monitor/component_state_monitor.launch.py` | 2 | [x] | [x] | n/a | n/a | n/a |
| `autoware_diagnostic_graph_aggregator/aggregator.launch.xml` | 2 | [x] | [x] | [x] | n/a | n/a |
| `autoware_mrm_comfortable_stop_operator/mrm_comfortable_stop_operator.launch.py` | 2 | [x] | [x] | [x] | n/a | n/a |
| `autoware_mrm_emergency_stop_operator/mrm_emergency_stop_operator.launch.py` | 2 | [x] | [x] | [x] | n/a | n/a |
| `autoware_hazard_status_converter/hazard_status_converter.launch.xml` | 1 | [x] | [x] | [x] | n/a | n/a |
| `autoware_mrm_handler/mrm_handler.launch.xml` | 1 | [x] | [x] | [x] | n/a | n/a |
| `autoware_duplicated_node_checker/duplicated_node_checker.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |
| `autoware_pipeline_latency_monitor/pipeline_latency_monitor.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |
| `autoware_processing_time_checker/processing_time_checker.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |
| `autoware_component_interface_tools/service_log_checker.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |

### Simulation (4 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `autoware_simple_planning_simulator/simple_planning_simulator.launch.py` | 1 | [x] | [x] | [x] | [x] | [x] |
| `autoware_detected_object_feature_remover/detected_object_feature_remover.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |
| `autoware_shape_estimation/shape_estimation.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |
| `autoware_vehicle_door_simulator/vehicle_door_simulator.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |

### API & Infrastructure (23 entities)

| File | Ent | Skeleton | Topics | QoS | Rates | Timing |
|------|-----|----------|--------|-----|-------|--------|
| `autoware_default_adapi_universe/default_adapi.launch.py` | 20 | [x] | [x] | n/a | n/a | n/a |
| `autoware_launch/pointcloud_container.launch.py` | 2 | [x] | [x] | n/a | n/a | n/a |
| `autoware_diagnostic_graph_utils/logging.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |
| `autoware_pose_initializer/pose_initializer.launch.xml` | 1 | [x] | [x] | n/a | n/a | n/a |

### Vehicle & Parameters (0 entities)

Pass-through only — no manifests needed:
- `tier4_vehicle_launch/vehicle.launch.xml`
- `autoware_vehicle_info_utils/vehicle_info.launch.py` (×4)
- `autoware_global_parameter_loader/global_params.launch.py` (×4)
- `autoware_launch/default_preset.yaml` (×2)
