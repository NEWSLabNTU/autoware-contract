# Per-Launch-File Implementation Status

Tracks which manifest format features have been applied to each Autoware
contract manifest. See [roadmap/](roadmap/) for feature definitions.

| Column | Feature | Phase |
|--------|---------|-------|
| **Skel** | Skeleton: nodes, imports/exports, paths | Done |
| **Topics** | Remapped topic names + message types | Done |
| **QoS** | reliability, durability, depth | Done |
| **Rates** | min_rate_hz, max_rate_hz | Done |
| **Timing** | max_latency_ms, max_age_ms | Done |
| **Svcs** | srv:/cli: on nodes + services: at scope | Done (endpoints), Phase 1+5 (contracts+wiring) |
| **SvcMs** | max_response_ms on srv/cli | Phase 1 |
| **Args** | args: + $(var ...) substitutions | Phase 2 |
| **Cond** | if:/unless: conditions | Phase 3 |
| **Valid** | Passed play_launch check end-to-end | Phase 4 |

---

## Control

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `control.yaml` | [x] | [x] | [x] | [x] | [x] | [x] | [ ] | [ ] | [ ] | [ ] |
| `external_cmd_converter.yaml` | [x] | [x] | [x] | n/a | [x] | n/a | n/a | [ ] | n/a | [ ] |
| `external_cmd_selector.yaml` | [x] | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |

## Planning — Mission

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `mission_planner.yaml` | [x] | [x] | [x] | [x] | [x] | [x] | [ ] | n/a | n/a | [ ] |
| `goal_pose_visualizer.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `manual_lane_change_handler.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |

## Planning — Behavior

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `behavior_planning.yaml` | [x] | [x] | [x] | [x] | [x] | n/a | n/a | [ ] | [ ] | [ ] |

## Planning — Motion

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `motion_planning.yaml` | [x] | [x] | [x] | [x] | [x] | n/a | n/a | [ ] | [ ] | [ ] |

## Planning — Scenario

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `scenario_selector.yaml` | [x] | [x] | [x] | [x] | [x] | n/a | n/a | [ ] | n/a | [ ] |
| `external_velocity_limit_selector.yaml` | [x] | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `hazard_lights_selector.yaml` | [x] | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `remaining_distance_time_calculator.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |

## Perception

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `map_based_prediction.yaml` | [x] | [x] | [x] | [x] | [x] | n/a | n/a | [ ] | n/a | [ ] |
| `multi_object_tracker.yaml` | [x] | [x] | [x] | [x] | [x] | n/a | n/a | [ ] | n/a | [ ] |
| `laserscan_based_occupancy_grid_map.yaml` | [x] | [x] | [x] | n/a | [x] | n/a | n/a | n/a | n/a | [ ] |

## Map

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `map_projection_loader.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |

## System

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `load_topic_state_monitor.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `load_topic_state_monitor_tf.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `component_state_monitor.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `aggregator.yaml` | [x] | [x] | [x] | n/a | n/a | [x] | [ ] | n/a | n/a | [ ] |
| `mrm_comfortable_stop_operator.yaml` | [x] | [x] | [x] | n/a | n/a | [x] | [ ] | n/a | n/a | [ ] |
| `mrm_emergency_stop_operator.yaml` | [x] | [x] | [x] | n/a | n/a | [x] | [ ] | n/a | n/a | [ ] |
| `hazard_status_converter.yaml` | [x] | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `mrm_handler.yaml` | [x] | [x] | [x] | n/a | n/a | [x] | [ ] | n/a | n/a | [ ] |
| `duplicated_node_checker.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `pipeline_latency_monitor.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `processing_time_checker.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `service_log_checker.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |

## Simulation

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `simple_planning_simulator.yaml` | [x] | [x] | [x] | [x] | [x] | [x] | [ ] | [ ] | [ ] | [ ] |
| `detected_object_feature_remover.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `shape_estimation.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `vehicle_door_simulator.yaml` | [x] | [x] | n/a | n/a | n/a | [x] | [ ] | n/a | n/a | [ ] |

## API & Infrastructure

| Manifest | Skel | Topics | QoS | Rates | Timing | Svcs | SvcMs | Args | Cond | Valid |
|----------|------|--------|-----|-------|--------|------|-------|------|------|-------|
| `default_adapi.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `pointcloud_container.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `logging.yaml` | [x] | [x] | n/a | n/a | n/a | n/a | n/a | n/a | n/a | [ ] |
| `pose_initializer.yaml` | [x] | [x] | n/a | n/a | n/a | [x] | [ ] | n/a | n/a | [ ] |
