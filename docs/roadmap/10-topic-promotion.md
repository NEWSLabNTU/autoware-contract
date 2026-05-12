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
| Leaf-declared topics (`topics:`) | **161** |
| `external: both` orphans | **697** |
| `external: pub` (half) | **34** |
| `external: sub` (half) | **77** |
| Total `external_topics:` entries | **808** |

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
