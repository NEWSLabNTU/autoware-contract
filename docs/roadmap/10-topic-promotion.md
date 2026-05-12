# Phase 10 — Topic Promotion Campaign

Promote topics from `external_topics:` (bulk-discovered runtime FQNs)
into first-class `topics:` declarations in leaf manifests, each with a
proper QoS profile. This unlocks the full runtime-enforcement rule
suite (consistency-runtime + qos-match-runtime + max-age-runtime +
rate-hierarchy-runtime + drop-rate-runtime + max-latency-runtime) for
the promoted topics, instead of just the type check that
`external_topics:` enables.

## Conventions

- Each leaf manifest's `topics:` block lives at scope ns inherited from
  its parent (the include key is a label, not a namespace component).
- Relative keys resolve at that scope ns (e.g. `mrm/comfortable_stop/status`
  under `/system` → `/system/mrm/comfortable_stop/status`).
- Absolute keys (`/foo/bar`) stay verbatim.
- Pub-only topics from in-tree nodes → planning_simulator.yaml gets
  `external: sub` (downstream consumer is external tooling).
- Sub-only topics consumed by in-tree nodes → planning_simulator.yaml
  gets `external: pub` (upstream producer is external).
- Both sides declared in tree → no `external_topics:` entry needed
  (remove redundant one).

## Status (snapshot)

| Metric | Count |
|--------|------:|
| Leaf-declared topics (`topics:`) | **163** |
| `external: both` orphans | **0** |
| `external: pub` (half) | **163** |
| `external: sub` (half) | **652** |
| Total `external_topics:` entries | **815** |

Static `play_launch check`: 63 manifests, 0 errors, 0 warnings.
Runtime `play_launch ... --enforce-rules=warn` on planning_simulator:
zero violations.

## Campaign progress

### Round 1 — ADAPI state pubs (8 / 8) ✓

Source: `autoware_default_adapi_universe/default_adapi.yaml`.
QoS: reliable + transient_local + depth=1 (canonical ADAPI state).

- [x] `/api/operation_mode/state`
- [x] `/api/routing/state`
- [x] `/api/localization/initialization_state`
- [x] `/api/fail_safe/mrm_state`
- [x] `/api/motion/state`
- [x] `/api/system/heartbeat`
- [x] `/api/vehicle/status`
- [x] `/api/vehicle/metrics`
- [x] `/api/vehicle/doors/status`

### Round 2 — ADAPI extras (10 / 10) ✓

- [x] `/api/routing/route`
- [x] `/api/system/diagnostics/status`
- [x] `/api/system/diagnostics/struct`
- [x] `/api/planning/steering_factors`
- [x] `/api/planning/velocity_factors`
- [x] `/api/vehicle/kinematics`
- [x] `/api/perception/objects`
- [x] `/api/fail_safe/mrm_request/list`
- [x] `/api/manual/remote/control_mode/status`
- [x] `/autoware/state`

### Round 3 — component_state_monitor (16 / 16) ✓

Source: `autoware_component_state_monitor/component_state_monitor.yaml`.
QoS: reliable + transient_local + depth=1.

`/system/component_state_monitor/component/{autonomous,launch}/<sub>`
for sub ∈ {control, localization, map, perception, planning, sensing,
system, vehicle}.

- [x] autonomous × 8 subsystems
- [x] launch × 8 subsystems

### Round 4 — Aggregator pre-remap aliases (4 / 4) ✓

Source: `autoware_diagnostic_graph_aggregator/aggregator.yaml`.

- [x] `/system/aggregator/struct`
- [x] `/system/aggregator/status`
- [x] `/system/aggregator/unknowns`
- [x] `/system/aggregator/availability`

### Round 5 — mrm_handler internals (13 / 13) ✓

Source: `autoware_mrm_handler/mrm_handler.yaml`. 8 inputs + 5 outputs.

- [x] inputs: `/system/mrm_handler/input/{api/operation_mode/state, control_mode, gear, mrm/{comfortable_stop,emergency_stop,pull_over}/status, odometry, operation_mode_availability}`
- [x] outputs: `/system/mrm_handler/output/{emergency_holding, gear, hazard, mrm/state, turn_indicators}`

### Round 6 — MRM operators + hazard_status_converter (8 / 9)

Source: `autoware_mrm_comfortable_stop_operator/`,
`autoware_mrm_emergency_stop_operator/`, `autoware_hazard_status_converter/`.

- [x] `/system/mrm/comfortable_stop/status` — comfortable_stop_operator pub + mrm_handler sub
- [x] `/system/mrm/emergency_stop/status` — emergency_stop_operator pub + mrm_handler sub
- [x] `/system/mrm/emergency_stop/control_cmd` — emergency_stop_operator pub
- [x] `/system/emergency_holding` — mrm_handler pub + hazard_status_converter sub
- [x] `/control/command/control_cmd` (sub side wired in emergency_stop_operator)
- [x] `/system/velocity_limit` — comfortable_stop_operator, `autoware_internal_planning_msgs/msg/VelocityLimit` reliable+transient_local+1
- [x] `/system/velocity_limit/clear` — same, `VelocityLimitClearCommand`
- [x] `/system/hazard_status` — hazard_status_converter, `autoware_system_msgs/msg/HazardStatusStamped`
- [ ] `/system/mrm/pull_over_manager/status` — needs leaf manifest for pull_over_manager package (not present in this Autoware install)

### Round 11 — Source-reviewed mop-up (155, all remaining)

Last batch. Per-cluster source review for the 155 topics that didn't
match earlier regex patterns. After this round **every** topic
observed by the runtime interceptor is annotated with the correct
side (in-tree vs external) — zero `external: both` remain.

`/control` (35) — vehicle_cmd_gate pre-remap input/output aliases:

- `/control/input/*` (24, upstream from planning/mrm/operator) → `external: pub`
- `/control/output/*` + `/control/gate_mode_cmd` + `/control/trajectory_follower_control_cmd` (11, vehicle_cmd_gate pubs) → `external: sub`
- `/control/kinematics`, `/control/trajectory` → `external: pub`

`/system` (19):

- `/system/pipeline_latency_monitor/*` (7) + `/system/processing_time_checker/metrics` (1) → `external: sub`
- `/system/converter/*` (2) → `external: sub`
- `/system/hazard_status_converter/{hazard_status, input/emergency_holding}` (2) → flip both sides
- `/system/mrm_comfortable_stop_operator/output/*` (3) + `/system/mrm_emergency_stop_operator/output/*` (2) → `external: sub`
- `/system/mrm_emergency_stop_operator/input/control/control_cmd` (1) → `external: pub`

`/api` (8):

- `/api/control/command/*` (4) + `/api/external/get/rtc_*` (2) → `external: sub`
- `/api/autoware/get/*` (2) → `external: pub`

`/default_adapi` (6) — adaptor pre-remap sub aliases:

- `/default_adapi/helpers/autoware_initial_pose_adaptor/*` (2) → `external: pub`
- `/default_adapi/helpers/autoware_routing_adaptor/input/*` (4) → `external: pub`

`/simulation` (8):

- `/simulation/debug/*` + `/simulation/dummy_perception_publisher/*` + `/simulation/shape_estimation/*` (5) → `external: sub`
- `/simulation/detected_object_feature_remover/{input,output}` + `/simulation/{input,objects}` (4) → mixed pub/sub

`/perception` (5) — debug processing_time → `external: sub`

`/occupancy_grid_map` (5) — virtual_scan + pointcloud → `external: sub`

`/planning` (66) — all remaining behavior pubs:

- `/planning/path_reference/*` (8) → `external: sub`
- `/planning/planning_factors/*` (~40, every behavior module) → `external: sub`
- `/planning/steering_factor/*` + `/planning/velocity_factor/*` → `external: sub`
- `/planning/scenario_selector/*`, `/planning/scenario_planning/*`, `/planning/mission_planning/*`, `/planning/turn_signal_decider/*` → `external: sub`
- `/planning/planning_validator/*` + `/planning/route_state` + `/planning/remaining_distance_time_calculator/*` (5) → `external: sub`

Infrastructure (~20):

- `/rosout`, `/parameter_events`, `/robot_description`, `/joint_states`, `/service_log`, `/logging_diag_graph/*`, `/system/emergency/*`, `/vehicle_door_simulator_node/*` → `external: sub`
- `/initialpose`, `/pose_reset`, `/traffic_signals`, `/rviz/routing/*`, `/awapi/tmp/*`, `/system/mrm/pull_over_manager/status` → `external: pub`

### Round 10 — Bulk planning/control/perception/occupancy half-external (302)

Continues the round-9 pattern. Most remaining `external: both`
entries under `/planning`, `/control`, `/perception` and
`/occupancy_grid_map` are pre-remap aliases, RTC outputs, scenario
controller channels, validator/evaluator publishers, or node-namespace
input/output forms — each clearly one-sided (in-tree pub, external
sub, or vice versa).

Major buckets (counts approximate per regex match):

- `/planning/auto_mode_status/*` + `/planning/cooperate_status/*` +
  `/planning/cooperate_commands/*` — RTC scenario outputs (60)
- `/planning/<node>/output/*`, `/planning/<node>/input/*` —
  pre-remap node-namespace forms (85 pub + 60 sub)
- `/planning/debug/objects_of_interest/*` — visualization markers (19)
- `/planning/mission_planning/route_marker`, `/route_selector/*`,
  `/state` — mission planner outputs (~8)
- `/planning/mission_planning/{checkpoint,goal}` — operator inputs (2)
- `/planning/scenario_planning/{lane_driving,cruise_planner_type,scenario,...}/markers,footprint,distance,stop_reason,...` — scenario controller outputs (~30)
- `/control/<node>/output/*`, `/input/*`, `/markers`, `/marker`,
  `/published_time` — pre-remap + viz (~80)
- `/perception/<node>/published_time`, `/cyclic_time_ms`,
  `/maneuver`, `/objects_with_feature`, `/perception_analytics_publisher/*` (~10)
- `/occupancy_grid_map/*` debug/metrics/input/output/concatenated (~14)

Total flipped: 302 (60 sub + 85 pub + 71 sub + 3 pub + 83 sub).

### Round 9 — Bulk half-external annotation (199)

Most remaining `external: both` topics under `/simulation`, `/external`,
`/control`, `/planning` are NOT genuine orphans — they're side-channel
outputs (debug/metrics/markers/virtual_wall) from in-tree nodes that
flow to external monitoring (rviz/rqt/dashboards), or simulator
inputs from in-tree publishers, or selector outputs consumed by
external operator tooling. Bulk-flip these to half-external so the
runtime engine knows which side is in-tree.

Pattern flips (no leaf manifest changes needed — the publisher /
subscriber is already known via the side annotation):

- [x] `/simulation/input/*` → `external: pub` (13 topics, upstream is autoware control)
- [x] `/simulation/output/*` → `external: sub` (13 topics, simulator pubs to external consumers)
- [x] `/external/selected/*` → `external: sub` (4 topics, external_cmd_selector pubs already leaf-declared)
- [x] `/control/*/debug/*` + `/metrics` + `/virtual_wall` + `/markers` + `/is_filter_activated*` + `/is_paused` + `/is_start_requested` + `/control_component_latency` → `external: sub` (40 topics)
- [x] `/planning/*/debug/*` + `/metrics` + `/virtual_wall(s)` + `/markers` + `/processing_time_ms` etc. → `external: sub` (156 topics)

### Round 8 — Map loader aliases + localization (5 / 5)

Map loader pre-remap + auxiliary outputs (4 — declared in `tier4_map_launch/map.yaml`):

- [x] `/map/vector_map_marker` — lanelet2_map_visualization marker stream
- [x] `/map/input/lanelet2_map` — lanelet2_map_visualization sub alias
- [x] `/map/output/lanelet2_map_marker` — lanelet2_map_visualization pub alias
- [x] `/map/output/pointcloud_map` — pointcloud_map_loader pub alias

Localization (1 — flipped to half-external, source package outside tree):

- [x] `/localization/initialization_state` — pose_initializer pub (external)

### Round 7 — Vehicle + perception (7 / 7)

Vehicle interface package outputs (4 — package is outside the contract
tree; entries flipped to `external: pub` to declare the upstream as
external):

- [x] `/vehicle/command/manual_control_cmd`
- [x] `/vehicle/command/manual_gear_command`
- [x] `/vehicle/status/actuation_status`
- [x] `/vehicle/status/battery_charge`

Perception pre-remap aliases (3 — declared alongside the canonical
remapped topics in the respective leaf manifests):

- [x] `/perception/object_recognition/prediction/map_based_prediction/input/objects`
- [x] `/perception/object_recognition/prediction/map_based_prediction/output/objects`
- [x] `/perception/object_recognition/tracking/output/objects`

### Pending clusters

#### High-value (manageable size, clear ownership)

- [ ] **Vehicle status reports** (`/vehicle/status/*`) ~10 topics —
  needs vehicle interface or vehicle_cmd_gate leaf manifest extension
- [ ] **Localization outputs** (`/localization/kinematic_state`,
  `/localization/acceleration`, `/localization/pose_with_covariance`) —
  pose_twist_fusion_filter already references some
- [ ] **Perception final outputs** (`/perception/object_recognition/objects`,
  `/perception/object_recognition/tracking/objects`) — predicted +
  tracked, ~10 topics
- [ ] **Planning final trajectory** (`/planning/scenario_planning/trajectory`,
  `/planning/scenario_planning/lane_driving/trajectory`) — central
  planning outputs

#### Medium-value

- [ ] `/control/*` non-debug (~40 topics) — controllers, gate, validators
- [ ] `/planning/*` non-debug (~50 topics) — behavior + motion planning
- [ ] `/simulation/*` (34 topics) — simulator-only, mostly inputs
- [ ] `/external/*` (4 both + 12 pub + 3 sub) — joystick + remote driver

#### Low-value (debug, metrics, markers — likely stay external)

- [ ] `/planning/*/debug/*` (~250 topics)
- [ ] `/control/*/debug/*` (~70 topics)
- [ ] `/system/pipeline_latency_monitor/debug/*` (7 topics)
- [ ] `/system/processing_time_checker/metrics` (1 topic)

These rarely need stricter checks than `consistency-runtime` (already
covered by `external: both` + type). Operators can promote individual
entries on demand.

## Sources of QoS information

Each round consults the upstream package source to extract the exact
QoS profile from the `rclcpp::QoS` constructor call. Where the spec is
documented in `autoware_adapi_specs/include/autoware/adapi_specs/*.hpp`
(the spec-class header) we cite it; otherwise the comment cites the
relevant `node.cpp:line`. Phase 36 runtime enforcement validates the
declared QoS against the runtime DDS-discovered QoS via the
`qos-match-runtime` rule (firing as a violation in `runtime_violations.jsonl`
if mismatched).

## Verification

After each round:

```sh
# Static
play_launch check --manifest-dir <this repo> autoware_launch planning_simulator.launch.xml map_path:=...

# Runtime
play_launch launch --enforce-rules=warn ... autoware_launch planning_simulator.launch.xml map_path:=...
# Check play_log/<ts>/runtime_violations.jsonl — should be empty.
```

Both must pass with zero violations before the round is closed.
