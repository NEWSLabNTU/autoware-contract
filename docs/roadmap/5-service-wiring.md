# Phase 5: Service Wiring

Add scope-level `services:` entries that wire `srv:` servers to `cli:` clients.

## Criteria

- Every `srv:` endpoint has a matching `services:` entry with `type:`
- Intra-scope client→server wiring declared where both are in the same manifest
- Cross-scope wiring documented as known gap (not yet supported)

## Work Items

### 5.1: Mission planner (intra-scope wiring)

- [x] `mission_planner.yaml` — 3 `services:` entries wiring route_selector
  `cli:` → mission_planner `srv:` (clear_route, set_lanelet_route, set_waypoint_route)
- [x] Fixed route_selector: changed `srv:` to `cli:` (it's a client that
  proxies requests to mission_planner)

### 5.2: System service nodes

- [x] `aggregator.yaml` — 2 `services:` entries (reset, set_initializing)
- [x] `mrm_comfortable_stop_operator.yaml` — `services:` for operate (OperateMrm)
- [x] `mrm_emergency_stop_operator.yaml` — `services:` for operate (OperateMrm)
- [x] `external_cmd_selector.yaml` — `services:` for select_external_command

### 5.3: MRM handler (cross-scope wiring) — documented limitation

- [x] `mrm_handler.yaml` — documented that `cli:` targets are in other scopes
  (comfortable_stop_operator, emergency_stop_operator). Cross-scope service
  wiring is not yet supported in the manifest format. The `service-wiring`
  rule will warn about these — accepted as known gap.

### Already had services:

- `pose_initializer.yaml` — already has `services:` (initialize)
- `simple_planning_simulator.yaml` — already has `services:` (control_mode_request, set_pose)
- `vehicle_door_simulator.yaml` — already has `services:` (doors/command, doors/layout)
