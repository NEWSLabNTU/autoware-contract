# Design Notes

Issues and observations discovered during manifest authoring. These feed back
into the manifest format design and checker tool improvements.

## 1. QoS Default — Resolved

`rclcpp::QoS(1)` defaults to **reliable/volatile/depth1** (from
`rmw_qos_profile_default`). This is well-defined — no ambiguity.
`InterProcessPollingSubscriber` is a subscription wrapper pattern, not a
different QoS profile — the underlying DDS QoS is still whatever the
constructor specifies.

Early manifests incorrectly marked planning pipeline topics as `best_effort`;
corrected to `reliable`. Only `SensorDataQoS()` (depth=5) is best_effort.

## 2. Variable Topic Names

Several nodes use `$(var input_pointcloud_topic_name)` and
`$(var input_objects_topic_name)` for topic remapping. These are resolved at
launch time from args. The manifest currently uses generic names like
`pointcloud` in imports — the actual resolved name depends on launch args.
`play_launch check` resolves these when given the launch file, but the manifest
alone doesn't capture the mapping.

## 3. Intra-Container Topics

Topics between composable nodes in the same container (e.g., `smoothed_path`
between elastic_band_smoother and path_optimizer) may use intra-process
communication, which bypasses DDS entirely. The QoS declaration in the manifest
still describes the DDS-level contract, but runtime graph monitoring won't see
intra-process messages on the DDS graph.

## 4. Service-Only Nodes — Resolved

Some nodes (e.g., pose_initializer) are primarily service-based — they don't
publish topics at a steady rate but respond to service calls. The manifest
format now supports `max_response_ms` on `srv:` and `cli:` endpoints
(Phase 1). ROS 2 has no native DDS mechanism for service deadlines, so
enforcement is runtime-only via interception.

## 5. Config-File Parameters Are Expanded in record.json

Some Autoware nodes are parameterized via **YAML config files** rather than
launch `<arg>` declarations. For example, `multi_object_tracker` gets its
input channel topics from a YAML file pointed to by `input_channels_path`.

Initially this seemed like a limitation — the manifest `args:` can capture
the config file path but not its contents. However, **the parser already
resolves these**: `record.json` contains the expanded parameters as scope
args (e.g., `input/detection01/objects = /perception/object_recognition/detection/objects`).
The manifest loader sees these in `scope.args` and can use them for `$(var ...)`
substitution.

This means the manifest can reference these values via `$(var ...)`.

**Decision (Option B)**: Manifest args should be declared as **required**
(no defaults) — record.json is the single source of truth for arg values.
The manifest declares *which* args it needs; the scope table provides the
values. This eliminates duplication and prevents drift between manifest
defaults and launch file defaults.

```yaml
args:
  input/detection01/objects:     # required — value from record.json scope
  input/detection01/channel:     # required
```

The only downside is manifests can't be validated standalone (without a
launch file). But `play_launch check` already requires a launch file, so
this is consistent with the current workflow.

## 6. `max_response_ms` Requires Source Traceability

**Decision**: Do not set `max_response_ms` unless the requirement can be
traced to a specific source:
- Autoware source code (timeout values, timer periods)
- Autoware design documents or online discussions
- Safety standards (e.g., ISO 26262 reaction time budgets)

If a service is believed to be safety-critical but no concrete requirement
exists in the source, leave a `# safety-critical — no documented requirement`
comment instead of inventing a number. Unsourced values create false
confidence — they look like requirements but are actually guesses.

**Consequence**: Phase 1 values (MRM 100ms, route 2000ms, NDT 5000ms) were
design targets without source traceability. They have been removed and
replaced with comments noting the safety relevance. Values will be added
back when:
1. A concrete requirement is found in Autoware source/docs, or
2. Runtime measurements via service call interception establish baselines

## 7. Condition Granularity Gap

Autoware's `motion_planning.launch.xml` conditionally enables velocity planner
**modules** (e.g., `launch_obstacle_stop_module`, `launch_obstacle_cruise_module`)
via `<let>` and conditional `<arg>` accumulation. However, these modules are all
loaded into the **same composable node** (`motion_velocity_planner`) — they're
plugin classes, not separate nodes.

The manifest `if:` / `unless:` system works at the node/topic level, not the
plugin level. A conditional module that changes the internal behavior of a
single node can't be expressed as `if:` on a node — the node always exists,
just with different plugins loaded.

For now, document module flags in `args:` comments but don't add `if:` on
the node itself. Phase 3 conditions are best suited for nodes/topics that
are truly conditionally present (e.g., `launch_collision_detector`
enabling/disabling a whole node in `control.launch.xml`).

**Finding from Phase 3**: Only `control.launch.xml` has real conditional
`<group if="...">` blocks for node-level inclusion. The 4 checker nodes
(control_validator, AEB, lane_departure_checker, collision_detector) got
`if:` conditions. All other "conditional" features in Autoware planning/
motion are plugin-level inside existing nodes — `if:` does not apply.

## 8. Conditional Endpoint References in Topics

When a node has `if:`, topics that reference its endpoints become partially
conditional — some subscribers may not exist at runtime. The user reading
the manifest may assume all endpoint refs are always active.

Adding `if:` on individual `pub:`/`sub:` entries was considered but rejected:
in cross-scope wiring, the condition context of the child node is not
available in the parent manifest. Even intra-scope, it duplicates the
condition already on the node.

**Solution** — `?` suffix on optional endpoint references:

```yaml
sub:
  - always_present_node/input             # required — checker errors if missing
  - conditional_node/input?               # optional — silently dropped if node filtered
```

- **Unmarked** ref → required. Checker errors if the node doesn't exist
  after condition filtering.
- **`?` suffix** → optional. Dropped during post-filter cleanup if the
  referenced node was filtered out. `?` stripped if node is present.

`?` is unambiguous — not valid in ROS 2 names (only alphanumeric, underscore,
slash). Machine-checkable — the tool validates the `?` refs, not just comments.

Prior art: AUTOSAR declares the full topology as a superset with variation
annotations; AADL uses `in modes` on connections matching subcomponent modes.
Both accept that the manifest is a template — variant resolution selects
the active subset.

## 9. Cross-Scope Service Wiring Not Supported

The manifest `services:` section wires `srv:` servers to `cli:` clients
**within a single scope**. Autoware's MRM system has cross-scope service
calls: `mrm_handler` (in its own scope) calls `operate` on operators in
separate scopes (`mrm_comfortable_stop_operator`, `mrm_emergency_stop_operator`).

The manifest format has no mechanism for cross-scope service wiring — there's
no import/export system for services like there is for topics. The
`service-wiring` rule will warn about unmatched `cli:` endpoints in this case.

**Options for future work**:
1. Add `service_imports:`/`service_exports:` analogous to topic imports/exports
2. Make the checker cross-scope aware (look across loaded manifests)
3. Accept the gap — cross-scope services are rare and the wiring can be
   verified at the parent scope level that includes both children

For now, option 3 is adopted. The limitation is documented in each affected
manifest file.

## 10. End-to-End Validation Results (Phase 4)

First full run of `play_launch check` against Autoware planning_simulator:

- **45 manifests loaded** (36 unique + 9 extra from ×10 topic_state_monitor)
- **0 errors** — all manifests pass static checks
- **149 warnings** — 146 wiring + 3 service-wiring
- **Wiring warnings are expected**: each manifest declares imports/exports for
  cross-scope endpoints, but no parent manifest wires them. The wiring rule
  checks intra-scope only.

**Fix applied**: `behavior_planning.yaml` had 2 args (`input_traffic_light_topic_name`,
`input_vector_map_topic_name`) that are not in the scope table — they have defaults
in the launch XML and are never passed from the parent. Removed from manifest args.

**Lesson**: only declare args that appear in `scope.args` (from record.json).
Args with defaults in the launch XML that are never overridden by the parent
don't appear in the scope table. The manifest should not declare them as
required.

**Update (Phase 7.3)**: After parser fix (33.1), all resolved args including
defaults now appear in `scope.args`. The 2 missing args have been re-added
to `behavior_planning.yaml`.

## 11. `?` Suffix Removed — Optionality Inferred from Conditions

The `?` suffix on optional endpoint refs was removed. Optionality is now
inferred automatically from node conditions:

- Ref to a node with `if:`/`unless:` → automatically optional (dropped
  silently when node is filtered out)
- Ref to an unconditional node → always required (checker errors if missing)

This eliminates the YAML compatibility issue (`?` broke PyYAML/yamllint
in flow sequences) and simplifies manifest authoring — just write the
ref, the tool figures out the rest.

All `?` suffixes removed from `control.yaml` (22 occurrences).

## 12. Cross-Scope Service Warnings Are Permanent Noise

`mrm_handler` has 3 `cli:` endpoints targeting servers in other scopes.
The `service-wiring` rule warns about these on every check run. With
scope-level `cli:` groups added (Phase 7.2), the *intent* is documented
but the checker still has no cross-scope awareness. There's no suppression
mechanism — these warnings can't be silenced.

3 permanent warnings per run from mrm_handler alone. As more cross-scope
services are documented, this will grow.

Tracked as design-issues.md #17.

## Upstream divergences (Phase 9 audit)

This audit fixed 11 `consistency` errors and 2 `rate-hierarchy` errors reported by
`play_launch check`. The fixes uncovered several places where Autoware source
code (or earlier manifest authoring) was internally inconsistent. Each is
documented inline near the manifest declaration with `# UPSTREAM:` comments.

### 1. `/map/vector_map` — subscriber depth ≠ publisher depth

- **Publisher**: `rclcpp::QoS{1}.transient_local()` (depth=1)
- **Source**: `src/core/autoware_core/map/autoware_map_loader/src/lanelet2_map_loader/lanelet2_map_loader_node.cpp:130`
- **Subscribers found at depth=10**:
  - `tier4_planning_launch/motion_planning.yaml` (motion_velocity_planner inline comment said depth=10)
  - `autoware_simple_planning_simulator/simple_planning_simulator.yaml` (sim subscribes with depth=10)
- **Our choice**: aligned all subscriber declarations to depth=1 (publisher wins).
- **Other vector_map subscribers** in `tier4_control_launch/control.yaml` and
  `autoware_remaining_distance_time_calculator/remaining_distance_time_calculator.yaml`
  had partial QoS (only `durability: transient_local`); filled in
  `reliability: reliable, depth: 1` to be explicit.

### 2. `/planning/scenario_planning/max_velocity_candidates` and `/.../clear_velocity_limit`

- **Publisher**: `rclcpp::QoS{1}.transient_local()` (depth=1)
  - Source: `src/core/autoware_core/planning/motion_velocity_planner/autoware_motion_velocity_planner/src/node.cpp:87-89`
- **Subscriber** (`external_velocity_limit_selector`): `QoS{10}.transient_local()` (depth=10)
  - Source: `src/universe/autoware_universe/planning/autoware_external_velocity_limit_selector/src/external_velocity_limit_selector_node.cpp:127,131`
- **Our choice**: aligned the manifest subscriber side to depth=1 (publisher wins).
  ROS 2 allows differing depth across pub/sub but the checker requires consistency
  in the declared contract. For transient_local control commands, only the latest
  message has meaning; depth>1 doesn't help.
- **Note**: the type field in our manifests still reads
  `tier4_planning_msgs/msg/VelocityLimit` and `tier4_planning_msgs/msg/VelocityLimitClearCommand`,
  but the actual upstream type is `autoware_internal_planning_msgs/msg/VelocityLimit{,ClearCommand}`
  (`include <autoware_internal_planning_msgs/msg/velocity_limit.hpp>` in both
  publisher node.hpp and subscriber selector_node.hpp). This is a separate
  authoring error not flagged by the checker because both pub and sub
  manifests share the same wrong type. Tracked for follow-up.

### 3. `/localization/kinematic_state` — subscriber depth=100

- **Publisher**: `QoS(1)` (depth=1) from simple_planning_simulator and EKF on real vehicle.
- **Subscriber** (`scenario_selector`): `QoS{100}` polling subscriber (depth=100).
- **Our choice**: aligned manifest subscriber to depth=1.

### 4. `/planning/scenario_planning/scenario` — wrong message package

- **Actual upstream type**: `autoware_internal_planning_msgs/msg/Scenario`
  - Publisher source: `src/universe/autoware_universe/planning/autoware_scenario_selector/src/node.cpp:482`
  - Subscribers (`behavior_path_planner`, `remaining_distance_time_calculator`,
    `costmap_generator`, `freespace_planner`) all `using autoware_internal_planning_msgs::msg::Scenario;`
- **Manifests previously declared**:
  - `autoware_scenario_selector/scenario_selector.yaml`: `tier4_planning_msgs/msg/Scenario` (wrong)
  - `tier4_planning_launch/behavior_planning.yaml`: `tier4_planning_msgs/msg/Scenario` (wrong)
  - `tier4_planning_launch/parking.yaml`: `tier4_planning_msgs/msg/Scenario` (wrong)
  - `autoware_remaining_distance_time_calculator/remaining_distance_time_calculator.yaml`: `autoware_planning_msgs/msg/Scenario` (wrong)
- **Our choice**: corrected all four to `autoware_internal_planning_msgs/msg/Scenario`.

### 5. `/system/hazard_lights_cmd` — TODO type filled in

- **Actual upstream type**: `autoware_vehicle_msgs/msg/HazardLightsCommand`
  - Publisher source: `src/universe/autoware_universe/system/autoware_command_mode_switcher_plugins/src/comfortable_stop.cpp:34`
- **Manifests**: `autoware_mrm_handler/mrm_handler.yaml` had `TODO/msg/TODO`. Fixed.
  `autoware_hazard_lights_selector/hazard_lights_selector.yaml` already used the
  correct type — the consistency error was triggered by the mrm_handler manifest
  declaring the topic with TODO/msg/TODO, not by hazard_lights_selector.

### 6. `/perception/object_recognition/detection/objects_with_feature` — wrong type

- **Actual upstream type**: `tier4_perception_msgs/msg/DetectedObjectsWithFeature`
  - Publisher source: `src/universe/autoware_universe/perception/autoware_shape_estimation/src/shape_estimation_node.cpp:47`
  - Subscriber header: `src/universe/autoware_universe/perception/autoware_detected_object_feature_remover/src/detected_object_feature_remover_node.hpp:23`
- **Manifests previously declared**:
  - `autoware_shape_estimation/shape_estimation.yaml`: `autoware_perception_msgs/msg/DetectedObjects` (wrong — topic suffix `_with_feature` signals the WithFeature variant)
  - `autoware_detected_object_feature_remover/detected_object_feature_remover.yaml`: `TODO/msg/TODO`
- **Our choice**: corrected both to `tier4_perception_msgs/msg/DetectedObjectsWithFeature`.

### 7. controller_node_exe sub min_rate_hz: simulator vs real-vehicle divergence

- **Real-vehicle** EKF publishes `/localization/kinematic_state` and
  `/localization/acceleration` at 50 Hz; controller's `min_rate_hz: 50` matches.
- **Simulator** (`simple_planning_simulator`) publishes both at `sim_hz=40` (default).
- **Source**: `src/universe/autoware_universe/simulator/autoware_simple_planning_simulator/src/simple_planning_simulator_core.cpp` (sim_hz default 40)
- **Our choice**: lowered controller `min_rate_hz` to 40 in
  `tier4_control_launch/control.yaml` to match the simulator-driven pipeline
  used by `planning_simulator.launch.xml`. For real-vehicle contracts this
  should be 50; comment in the file flags the divergence.

## 13. External Topics — Resolved by `external_topics:` (Phase 35.10)

After Phase 9 the checker initially reported 39 dangling-entity
warnings. The block was tracked as play_launch design issue #51 and
resolved by adding a top-level `external_topics:` block to the
manifest format (Phase 35.10). The new block is now declared at
`autoware_launch/planning_simulator.yaml` and silences all
truly-external producers + consumers. The repo currently builds
clean (`0 errors, 0 warnings`).

This section is preserved as a historical record of the categorization
and the path from "many warnings" to "clean repo".

### Why this happens

A topic is "dangling" in the cross-scope merge when no manifest
declares a producer for it. There are three reasons:

1. **Truly external** — produced by a system outside Autoware (or
   outside this repo's scope): TF broadcaster, vehicle hardware,
   sensor drivers, map_loader package, ROS standard topics like
   `/diagnostics`. We will never author a manifest for these.
2. **Incomplete manifest coverage** — produced by a launched Autoware
   node, but the producing leaf manifest doesn't declare the topic on
   the publisher side. Fix is to add the `pub:` declaration in the
   producing manifest.
3. **TODO / generic topics** — placeholders we left unresolved
   (`type: TODO/msg/TODO`) or topics whose name is launch-arg
   parameterized (e.g. monitored_topic in topic_state_monitor).

The checker can't tell which is which without a format mechanism for
declaring external producers.

### Triage of current 39 warnings

| Category | Count | Action |
|---|---|---|
| Truly external (no Autoware producer) | ~5 | Need `external_topics:` block (issue #51) |
| Incomplete manifest coverage (Autoware producer not yet manifested) | ~28 | Author missing producer decl; do not suppress |
| TODO placeholders / generic monitors | ~6 | Resolve types or accept as parameterized |

#### Truly external

| Topic | Producer | Note |
|---|---|---|
| `/tf` | tf2_broadcaster (any node using tf2) | System frame |
| `/gnss_pose` | GNSS driver | Real-vehicle hardware; absent in `planning_simulator` |
| `/point_cloud_map` | `autoware_map_loader` (separate package, not in this contract repo's scope) | Could be authored as its own contract repo |
| `/door_command` | External fleet management or human input | Vehicle door command source |
| `/diagnostics_graph` (bare topic, not the `/struct`/`/status` variants) | unclear — may be a manifest typo, audit needed | Open question |

These need the spec change in #51 before they can be silenced cleanly.
Until then they are documented as accepted noise.

#### Incomplete manifest coverage

These are topics produced by Autoware nodes that **are** launched in
`planning_simulator.launch.xml` but whose leaf manifest doesn't list
them under any `topics:` key with a `pub:` line. Examples of producers
not yet authored as full leaf manifests:

- `vehicle_cmd_gate` (publishes `/control/command/control_cmd`,
  `/control/command/gear_cmd`, `/control/command/turn_indicators_cmd`,
  `/control/command/hazard_lights_cmd`, `/control/current_gate_mode`,
  `/system/command_mode/availability`)
- `external_cmd_selector` output side
  (`/external/selected/gear_cmd` etc. — selector exists in our
  manifests but its outputs aren't declared)
- `behavior_path_planner` (publishes
  `/planning/behavior_path_planner/hazard_lights_cmd`)
- `scenario_planning` output (`/planning/trajectory`)
- `motion_velocity_planner` debug
  (`/planning/scenario_planning/max_velocity_default`)
- `freespace_planner` parking branch
  (`/planning/scenario_planning/parking/trajectory` etc.)
- `operation_mode_transition_manager`
  (`/system/operation_mode/state`, `/api/operation_mode/state`)
- `diagnostic_graph_aggregator`
  (`/system/emergency_holding`, `/diagnostics_graph` variants)
- `obstacle_segmentation` output
  (`/perception/obstacle_segmentation/pointcloud`)
- `lidar_centerpoint` / `lidar_apollo_instance_segmentation`
  detector outputs
  (`/perception/object_recognition/detection/labeled_clusters`,
  `/occupancy_grid_map/no_ground/oneshot/pointcloud`)
- `traffic_light_classifier` (when traffic_light arg is true)
  (`/perception/traffic_light_recognition/traffic_signals`)

These warnings are **legitimate signal** — they tell us where the
contract coverage is incomplete. We should treat them as a follow-up
authoring backlog, not as noise.

#### TODO placeholders / generic monitors

- `/planning/mission_planning/lane_change_command` — placeholder, real
  type unknown (manual_lane_change_handler.yaml carries a TODO)
- `/planning/scenario_planning/scenario_selector/is_parking_completed`
  — same, scenario_selector source check needed
- `/planning/scenario_planning/scenario_selector_trajectory` — same
- `/system/topic_state_monitor/monitored_topic` — generic by design;
  the actual topic name is launch-arg parameterized. The manifest
  currently uses a placeholder absolute key that never matches a real
  topic. Better modeled as an external_topic with an arg-parameterized
  name once #51 lands.
- `/system/pipeline_latency_monitor/topics_to_monitor` — same generic
  pattern.
- `/system/processing_time_checker/processing_times` — same.

### Resolution (all done)

1. **Spec side**: #51 landed in play_launch Phase 35.10
   (`external_topics:` block + per-topic `external:` flag).
2. **Repo side**: 49 entries added to
   `autoware_launch/planning_simulator.yaml` covering all categories
   (system frame, vehicle interface, sensor drivers, map loader,
   external cmd sources, conditional excludes, out-of-tree
   consumers/producers).
3. **Repo side**: Phase 9.x backlog cleared — incomplete-coverage
   topics either authored as new leaf manifests
   (`autoware_vehicle_cmd_gate`,
   `autoware_operation_mode_transition_manager`,
   `autoware_dummy_perception_publisher`) or marked external in the
   block where appropriate.
4. **Repo side**: TODO placeholder types resolved against Autoware
   source — see §1–§7 of this doc for the upstream divergences logged.

CI policy: `0 errors` AND `0 warnings` is now the gate. Both
currently met (`63 manifests checked: 63 clean, 0 errors, 0
warnings`).

### Inventory of accepted external topics (post Phase 9)

After the Phase 9 cleanup pass (parameterized monitors dropped,
`/perception/object_recognition/tracking/detected_objects` placeholder
removed from the multi_object_tracker manifest, vehicle_door_simulator
fixed to declare `/vehicle/doors/status`), the remaining
dangling-entity warnings split into two camps: incomplete manifest
coverage (Autoware producers not yet authored — see the table above)
and **truly external** (no Autoware producer in
`planning_simulator.launch.xml`).

The inventory below documents the truly-external set. All entries
are now declared in `autoware_launch/planning_simulator.yaml` under
`external_topics:` and silenced cleanly via Phase 35.10's
`external_topics:` block. Preserved here for reference.

| Topic | External producer | Notes |
|---|---|---|
| `/tf` | `tf2_ros::TransformBroadcaster` invoked by many nodes / system frame | Standard ROS frame topic. |
| `/gnss_pose` | GNSS driver (real-vehicle hardware) | Absent in `planning_simulator.launch.xml` — the simulator does not include a GNSS driver. |
| `/point_cloud_map` | `autoware_map_loader` (separate package, not in this contract repo's scope) | Could be authored as its own contract repo; out of scope here. |
| `/vehicle/engage` | External: joystick, teleop, fleet management, or HMI | `autoware_default_adapi_universe` consumes this; the producer is operator/teleop input, not an Autoware node in the simulator graph. |
| `/external/local/heartbeat` | External: local-control input device (joystick / keyboard driver) | Liveness signal from a local cmd source. Not produced by any Autoware node in `planning_simulator`. |
| `/external/local/pedals_cmd` | External: local-control input device | Throttle/brake from local driver console. |
| `/external/local/steering_cmd` | External: local-control input device | Steering from local driver console. |
| `/external/remote/heartbeat` | External: remote-control teleop link | Liveness signal from a remote operator station. |
| `/external/remote/pedals_cmd` | External: remote-control teleop link | Throttle/brake from remote operator station. |
| `/external/remote/steering_cmd` | External: remote-control teleop link | Steering from remote operator station. |

The `/external/local/*` and `/external/remote/*` families are inputs to
`autoware_external_cmd_selector`; the selector merges them into
`/external/selected/*`. These six are inherently external in any real
or simulated deployment because they originate at human-driver input
devices.

Action: leaf manifests stay unchanged — the truly-external entries
all live in `autoware_launch/planning_simulator.yaml`'s
`external_topics:` block (Phase 35.10).
