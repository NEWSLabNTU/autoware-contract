# Phase 8: Intermediate Manifests + Leaf Manifest Gaps

Complete the manifest tree by authoring intermediate (orchestration-only)
manifests and filling gaps in existing leaf manifests.

Depends on: Phase 7 (format v2 adoption, complete).

## 8.1: Fix gaps in existing leaf manifests

Leaf manifests with unchecked feature columns in status.md.

- [x] 8.1.1: `behavior_planning.yaml` — Cond: behavior_path_planner_type
  selects between BehaviorPathPlannerNode and PathGenerator (plugin-level,
  see notes.md #7 — document in comments only, not `if:`)
- [x] 8.1.2: `motion_planning.yaml` — Cond: motion_path_smoother_type and
  motion_path_planner_type select between implementations (plugin-level,
  same as above)
- [x] 8.1.3: `simple_planning_simulator.yaml` — Cond: motion_publish_mode
  changes topic remapping (pose_only vs full_motion). Already has
  `choices: [full_motion, pose_only]` on the arg. No node-level `if:`
  needed — the node always exists, only remaps change.
- [x] 8.1.4: `external_cmd_converter.yaml` — Args: launch file has args
  for CSV paths, gains, timeouts. Most are param paths (not manifest
  args). Review which belong in `args:`.

## 8.2: Tier 3 subsystem aggregators (highest priority)

These wire child scopes together and declare subsystem interfaces.

- [x] 8.2.1: `tier4_system_launch/system.yaml` — 14 children
  - Key: wires MRM handler ↔ operators (cross-scope services)
  - Includes: aggregator, mrm_handler, mrm_comfortable_stop_operator,
    mrm_emergency_stop_operator, hazard_status_converter, component_state_monitor,
    duplicated_node_checker, processing_time_checker, pipeline_latency_monitor,
    service_log_checker, (+ conditional: system_monitor, dummy_diag_publisher,
    command_mode_switcher, command_mode_decider)
  - Services: wire OperateMrm between mrm_handler (cli) and operators (srv)
  - Conditions: use_control_command_gate, launch_system_monitor,
    launch_dummy_diag_publisher
- [x] 8.2.2: `tier4_planning_launch/planning.yaml` — 6 children
  - Includes: manual_lane_change_handler, mission_planning, scenario_planning,
    planning_validator, planning_evaluator,
    remaining_distance_time_calculator (conditional)
  - Namespace: /planning
- [x] 8.2.3: `tier4_perception_launch/perception.yaml` — 8 children
  - Includes: ground_segmentation, occupancy_grid_map, detection, tracking,
    prediction, traffic_light (conditional), perception_online_evaluator
    (conditional), perception_analytics_publisher (conditional)
  - Namespace: /perception
  - Has own node: empty_objects_publisher (conditional)
  - Has composable node: PointcloudDownsampleFilter (conditional)
- [x] 8.2.4: `tier4_simulator_launch/simulator.yaml` — 14 children
  - Includes: fault_injection (conditional), dummy_perception (conditional),
    occupancy_grid_map, multi_object_tracker (conditional), prediction
    (conditional), traffic_light (conditional), pose_initializer (conditional),
    gyro_odometer, pose_twist_fusion_filter, vehicle_door_simulator
    (conditional), simple_planning_simulator (conditional)
  - Has own nodes: vehicle_velocity_converter, scenario_simulator_adapter
    (conditional), elevation_map_loader (conditional), empty_objects_publisher
    (conditional)
  - Many conditions based on launch_dummy_*, perception/enable_*, localization_sim_mode
- [x] 8.2.5: `tier4_localization_launch/localization.yaml` — 3 children
  - Includes: pose_twist_estimator, pose_twist_fusion_filter,
    localization_error_monitor
  - Namespace: /localization
- [x] 8.2.6: `tier4_sensing_launch/sensing.yaml` — 1 child
  - Includes: sensor-model-specific sensing.launch.xml
  - Namespace: /sensing
- [x] 8.2.7: `tier4_map_launch/map.yaml` — 1 child + own nodes
  - Includes: map_projection_loader
  - Has own nodes: pointcloud_map_loader, lanelet2_map_loader,
    lanelet2_map_visualization, vector_map_tf_generator, map_hash_generator
  - Namespace: /map
- [x] 8.2.8: `tier4_autoware_api_launch/autoware_api.yaml` — 4 children
  - Includes: deprecated_api (conditional), default_adapi (conditional),
    rviz_adaptors (conditional), rosbridge (conditional)
  - Has own node: RTCController composable node

## 8.3: Tier 3b — Planning sub-modules

- [x] 8.3.1: `tier4_planning_launch/mission_planning.yaml`
  - Includes: mission_planner, goal_pose_visualizer
- [x] 8.3.2: `tier4_planning_launch/scenario_planning.yaml`
  - Includes: scenario_selector, external_velocity_limit_selector,
    hazard_lights_selector, lane_driving, parking
  - Has own nodes: velocity_smoother (composable)
- [x] 8.3.3: `tier4_planning_launch/lane_driving.yaml`
  - Includes: behavior_planning, motion_planning
  - Namespace: lane_driving/behavior_planning + lane_driving/motion_planning
- [x] 8.3.4: `tier4_planning_launch/parking.yaml`
  - Has own nodes: costmap_generator, freespace_planner (composable)
  - Namespace: parking

## 8.4: Tier 3c — Perception sub-modules

- [x] 8.4.1: `tier4_perception_launch/detection.yaml` — complex
  - Mode-based pipeline selection (camera, lidar, fusion variants)
  - 60+ args, 70+ let statements, many conditional includes
  - Lower priority — most detection nodes don't have leaf manifests yet
- [x] 8.4.2: `tier4_perception_launch/tracking.yaml`
  - Includes: multi_object_tracker + conditional radar fusion
- [x] 8.4.3: `tier4_perception_launch/prediction.yaml`
  - Includes: map_based_prediction (conditional on prediction_model_type)
- [x] 8.4.4: `tier4_perception_launch/traffic_light.yaml`
  - Traffic light recognition pipeline
- [x] 8.4.5: `tier4_perception_launch/ground_segmentation.yaml`
  - Ground filtering pipeline
- [x] 8.4.6: `tier4_perception_launch/occupancy_grid_map.yaml`
  - Occupancy grid map pipeline

## 8.5: Tier 3d — Localization sub-modules

- [x] 8.5.1: `tier4_localization_launch/pose_twist_estimator.yaml` — complex
  - Conditional includes based on pose_source/twist_source args
  - NDT, YabLoc, Eagleye, AR tag, gyro odometer, etc.
- [x] 8.5.2: `tier4_localization_launch/pose_twist_fusion_filter.yaml`
  - Includes: ekf_localizer, stop_filter, twist2accel, pose_instability_detector
- [x] 8.5.3: `tier4_localization_launch/localization_error_monitor.yaml`
  - Simple wrapper: includes localization_error_monitor

## 8.6: Tier 2 — Component wrappers

Thin wrappers that load global params + include one tier 3 subsystem.
These are low priority — they mostly pass args through.

- [x] 8.6.1: `autoware_launch/tier4_system_component.yaml`
- [x] 8.6.2: `autoware_launch/tier4_control_component.yaml`
- [x] 8.6.3: `autoware_launch/tier4_planning_component.yaml`
- [x] 8.6.4: `autoware_launch/tier4_perception_component.yaml`
- [x] 8.6.5: `autoware_launch/tier4_localization_component.yaml`
- [x] 8.6.6: `autoware_launch/tier4_simulator_component.yaml`
- [x] 8.6.7: `autoware_launch/tier4_sensing_component.yaml`
- [x] 8.6.8: `autoware_launch/tier4_map_component.yaml`
- [x] 8.6.9: `autoware_launch/tier4_autoware_api_component.yaml`

## 8.7: Tier 1 — Entry point

- [x] 8.7.1: `autoware_launch/planning_simulator.yaml`
  - Top-level orchestrator: includes 9 component wrappers + simulator

---

## Priority Order

```
8.1 (leaf gaps)     ─────────────────────────────────────┐
                                                         │
8.2 (tier 3 aggregators) ───────────────────────────────┤
  8.2.1 system.yaml (highest — MRM cross-scope wiring) │
  8.2.2 planning.yaml                                   │
  8.2.5 localization.yaml                               │
  8.2.7 map.yaml (has own nodes)                        │
  8.2.3 perception.yaml                                 │
  8.2.4 simulator.yaml                                  │
  8.2.6 sensing.yaml                                    │
  8.2.8 autoware_api.yaml                               │
                                                         │
8.3 (planning sub-modules) ─────────────────────────────┤
8.4 (perception sub-modules) ───────────────────────────┤
8.5 (localization sub-modules) ─────────────────────────┤
                                                         │
8.6 (tier 2 wrappers) ─────────────────────────────────┤
8.7 (tier 1 entry point) ──────────────────────────────┘
```

8.1 is quick cleanup. 8.2.1 (system.yaml) is highest impact — resolves
design issue #17 (cross-scope service warnings). Remaining tier 3
aggregators follow. Tier 3b-d sub-modules fill in the tree. Tier 2
wrappers and tier 1 entry point are last (lowest impact).
