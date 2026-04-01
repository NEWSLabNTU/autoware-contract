# Per-Launch-File Implementation Status

Tracks manifest coverage for the Autoware planning_simulator launch tree.
See [roadmap/](roadmap/) for feature definitions.

## Feature Columns (Leaf Manifests)

| Column     | Feature                                 | Phase                                          |
|------------|-----------------------------------------|------------------------------------------------|
| **Skel**   | Skeleton: nodes, pub/sub, paths         | Done                                           |
| **Topics** | Remapped topic names + message types    | Done                                           |
| **QoS**    | reliability, durability, depth          | Done                                           |
| **Rates**  | min_rate_hz, max_rate_hz                | Done                                           |
| **Timing** | max_latency_ms, max_age_ms              | Done                                           |
| **Svcs**   | srv:/cli: on nodes + services: at scope | Done (endpoints), Phase 1+5 (contracts+wiring) |
| **ScoSvc** | Scope-level srv:/cli: groups            | Phase 7.2                                      |
| **Args**   | args: + $(var ...) + type/choices       | Phase 2 + 7.1                                  |
| **Cond**   | if:/unless: conditions                  | Phase 3                                        |
| **Valid**  | Passed play_launch check end-to-end     | Phase 4                                        |

---

## Intermediate Manifests (includes only, no nodes)

Intermediate launch files orchestrate children via `<include>`. Their
manifests declare `includes:` and scope interface (`pub:`/`sub:`/`srv:`/
`cli:`) to wire children together across namespace boundaries.

### Tier 1 — Top Level

| Launch file (pkg / file)                        | Includes | Status |
|-------------------------------------------------|----------|--------|
| `autoware_launch/planning_simulator.launch.xml` | 9        | [ ]    |

### Tier 2 — Component Wrappers (autoware_launch/components/)

Thin wrappers: load global params + include one tier 3 subsystem.

| Launch file                               | Includes                    | Status |
|-------------------------------------------|-----------------------------|--------|
| `tier4_system_component.launch.xml`       | system.launch.xml + logging | [ ]    |
| `tier4_control_component.launch.xml`      | control.launch.xml          | [ ]    |
| `tier4_planning_component.launch.xml`     | planning.launch.xml         | [ ]    |
| `tier4_perception_component.launch.xml`   | perception.launch.xml       | [ ]    |
| `tier4_localization_component.launch.xml` | localization.launch.xml     | [ ]    |
| `tier4_simulator_component.launch.xml`    | simulator.launch.xml        | [ ]    |
| `tier4_sensing_component.launch.xml`      | sensing.launch.xml          | [ ]    |
| `tier4_map_component.launch.xml`          | map.launch.xml              | [ ]    |
| `tier4_autoware_api_component.launch.xml` | autoware_api.launch.xml     | [ ]    |

### Tier 3 — Subsystem Aggregators

Main subsystem launch files. Include leaf launch files and sub-modules.
Manifests here wire cross-scope services and declare subsystem interfaces.

| Launch file (pkg / file)                            | Children | Status | Notes                                                |
|-----------------------------------------------------|----------|--------|------------------------------------------------------|
| `tier4_system_launch/system.launch.xml`             | 14       | [ ]    | Wires MRM handler ↔ operators (cross-scope services) |
| `tier4_planning_launch/planning.launch.xml`         | 6        | [ ]    | Mission + scenario planning orchestration            |
| `tier4_perception_launch/perception.launch.xml`     | 8        | [ ]    | Detection, tracking, traffic lights                  |
| `tier4_control_launch/control.launch.xml`           | 5        | [x]    | Has own nodes + children (`control.yaml`)            |
| `tier4_simulator_launch/simulator.launch.xml`       | 14       | [ ]    | Dummy perception + vehicle sim                       |
| `tier4_localization_launch/localization.launch.xml` | 3        | [ ]    | Estimator, fusion, monitoring                        |
| `tier4_sensing_launch/sensing.launch.xml`           | 1        | [ ]    | Sensor drivers                                       |
| `tier4_map_launch/map.launch.xml`                   | 1        | [ ]    | Map loading                                          |
| `tier4_autoware_api_launch/autoware_api.launch.xml` | ?        | [ ]    | ADAPI endpoints                                      |

### Tier 3b — Planning Sub-modules

| Launch file (pkg / file)                                 | Status | Notes                                           |
|----------------------------------------------------------|--------|-------------------------------------------------|
| `tier4_planning_launch/.../mission_planning.launch.xml`  | [ ]    | Includes mission_planner + goal_pose_visualizer |
| `tier4_planning_launch/.../scenario_planning.launch.xml` | [ ]    | Lane driving + parking orchestration            |
| `tier4_planning_launch/.../lane_driving.launch.xml`      | [ ]    | Includes behavior + motion planning             |
| `tier4_planning_launch/.../parking.launch.xml`           | [ ]    | Parking planner                                 |

### Tier 3c — Perception Sub-modules

| Launch file (pkg / file)                                                  | Status | Notes                              |
|---------------------------------------------------------------------------|--------|------------------------------------|
| `tier4_perception_launch/.../detection.launch.xml`                        | [ ]    | Detector selection + filtering     |
| `tier4_perception_launch/.../tracking.launch.xml`                         | [ ]    | Includes multi_object_tracker      |
| `tier4_perception_launch/.../prediction.launch.xml`                       | [ ]    | Includes map_based_prediction      |
| `tier4_perception_launch/.../traffic_light.launch.xml`                    | [ ]    | Traffic light recognition pipeline |
| `tier4_perception_launch/.../ground_segmentation.launch.py`               | [ ]    | Ground filtering                   |
| `tier4_perception_launch/.../probabilistic_occupancy_grid_map.launch.xml` | [ ]    | Occupancy grid                     |

### Tier 3d — Localization Sub-modules

| Launch file (pkg / file)                                            | Status | Notes                    |
|---------------------------------------------------------------------|--------|--------------------------|
| `tier4_localization_launch/.../pose_twist_estimator.launch.xml`     | [ ]    | NDT, gyro odometer, etc. |
| `tier4_localization_launch/.../pose_twist_fusion_filter.launch.xml` | [ ]    | EKF fusion               |
| `tier4_localization_launch/.../localization_error_monitor.launch.xml` | [ ]  | Error monitoring         |

---

## Leaf Manifests (36 files)

### Control

| Manifest                      | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|-------------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `control.yaml`                | [x]  | [x]    | [x] | [x]   | [x]    | [x]  | n/a    | [x]  | [x]  | [x]   |
| `external_cmd_converter.yaml` | [x]  | [x]    | [x] | n/a   | [x]    | n/a  | n/a    | [ ]  | n/a  | [x]   |
| `external_cmd_selector.yaml`  | [x]  | [x]    | [x] | n/a   | n/a    | [x]  | [x]    | n/a  | n/a  | [x]   |

### Planning — Mission

| Manifest                          | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|-----------------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `mission_planner.yaml`            | [x]  | [x]    | [x] | [x]   | [x]    | [x]  | [x]    | n/a  | n/a  | [x]   |
| `goal_pose_visualizer.yaml`       | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `manual_lane_change_handler.yaml` | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |

### Planning — Behavior

| Manifest                 | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|--------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `behavior_planning.yaml` | [x]  | [x]    | [x] | [x]   | [x]    | n/a  | n/a    | [x]  | [ ]  | [x]   |

### Planning — Motion

| Manifest               | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `motion_planning.yaml` | [x]  | [x]    | [x] | [x]   | [x]    | n/a  | n/a    | [x]  | [ ]  | [x]   |

### Planning — Scenario

| Manifest                                  | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|-------------------------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `scenario_selector.yaml`                  | [x]  | [x]    | [x] | [x]   | [x]    | n/a  | n/a    | [x]  | n/a  | [x]   |
| `external_velocity_limit_selector.yaml`   | [x]  | [x]    | [x] | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `hazard_lights_selector.yaml`             | [x]  | [x]    | [x] | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `remaining_distance_time_calculator.yaml` | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |

### Perception

| Manifest                                  | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|-------------------------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `map_based_prediction.yaml`               | [x]  | [x]    | [x] | [x]   | [x]    | n/a  | n/a    | [x]  | n/a  | [x]   |
| `multi_object_tracker.yaml`               | [x]  | [x]    | [x] | [x]   | [x]    | n/a  | n/a    | [x]  | n/a  | [x]   |
| `laserscan_based_occupancy_grid_map.yaml` | [x]  | [x]    | [x] | n/a   | [x]    | n/a  | n/a    | n/a  | n/a  | [x]   |

### Map

| Manifest                     | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|------------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `map_projection_loader.yaml` | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |

### System

| Manifest                             | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|--------------------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `load_topic_state_monitor.yaml`      | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `load_topic_state_monitor_tf.yaml`   | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `component_state_monitor.yaml`       | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `aggregator.yaml`                    | [x]  | [x]    | [x] | n/a   | n/a    | [x]  | [x]    | n/a  | n/a  | [x]   |
| `mrm_comfortable_stop_operator.yaml` | [x]  | [x]    | [x] | n/a   | n/a    | [x]  | [x]    | n/a  | n/a  | [x]   |
| `mrm_emergency_stop_operator.yaml`   | [x]  | [x]    | [x] | n/a   | n/a    | [x]  | [x]    | n/a  | n/a  | [x]   |
| `hazard_status_converter.yaml`       | [x]  | [x]    | [x] | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `mrm_handler.yaml`                   | [x]  | [x]    | [x] | n/a   | n/a    | [x]  | [x]    | n/a  | n/a  | [x]   |
| `duplicated_node_checker.yaml`       | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `pipeline_latency_monitor.yaml`      | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `processing_time_checker.yaml`       | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `service_log_checker.yaml`           | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |

### Simulation

| Manifest                               | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|----------------------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `simple_planning_simulator.yaml`       | [x]  | [x]    | [x] | [x]   | [x]    | [x]  | [x]    | [x]  | [ ]  | [x]   |
| `detected_object_feature_remover.yaml` | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `shape_estimation.yaml`                | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `vehicle_door_simulator.yaml`          | [x]  | [x]    | n/a | n/a   | n/a    | [x]  | [x]    | n/a  | n/a  | [x]   |

### API & Infrastructure

| Manifest                    | Skel | Topics | QoS | Rates | Timing | Svcs | ScoSvc | Args | Cond | Valid |
|-----------------------------|------|--------|-----|-------|--------|------|--------|------|------|-------|
| `default_adapi.yaml`        | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `pointcloud_container.yaml` | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `logging.yaml`              | [x]  | [x]    | n/a | n/a   | n/a    | n/a  | n/a    | n/a  | n/a  | [x]   |
| `pose_initializer.yaml`     | [x]  | [x]    | n/a | n/a   | n/a    | [x]  | [x]    | n/a  | n/a  | [x]   |

---

## Coverage Summary

| Category                           | Total | Done | Remaining |
|------------------------------------|-------|------|-----------|
| Leaf manifests (with nodes)        | 36    | 36   | 0         |
| Tier 3 subsystem aggregators       | 9     | 1    | 8         |
| Tier 3b planning sub-modules       | 4     | 0    | 4         |
| Tier 3c perception sub-modules     | 6     | 0    | 6         |
| Tier 3d localization sub-modules   | 3     | 0    | 3         |
| Tier 2 component wrappers          | 9     | 0    | 9         |
| Tier 1 entry point                 | 1     | 0    | 1         |
| **Total**                          | **68**| **37** | **31**  |

**Priority order**:
1. Tier 3 subsystem aggregators — wire cross-scope services, declare subsystem interfaces
2. Tier 3b-d sub-modules — complete the intermediate tree
3. Tier 2 component wrappers — thin, mostly pass-through
4. Tier 1 entry point — top-level orchestration
