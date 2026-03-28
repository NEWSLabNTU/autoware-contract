# Phase 1: Service Contracts

Add `max_response_ms` to service endpoints. Currently `srv:` and `cli:` declare
existence only.

## Criteria

- Every `srv:` and `cli:` endpoint with a latency requirement has `max_response_ms`
- Values sourced from Autoware design specs or measured via CARET/interception
- Source cited in inline `#` comment

## Work Items

### 1.1: MRM services (latency-critical)

MRM activation must be fast — safety-critical path.

- [ ] `mrm_handler.yaml` — 3 `cli:` endpoints: `max_response_ms: 100` (design target)
- [ ] `mrm_comfortable_stop_operator.yaml` — `operate` server: `max_response_ms: 100`
- [ ] `mrm_emergency_stop_operator.yaml` — `operate` server: `max_response_ms: 50`

### 1.2: Mission planning services

Route changes must complete before next planning cycle.

- [ ] `mission_planner.yaml` — `clear_route`: `max_response_ms: 500`,
  `set_lanelet_route`: `max_response_ms: 2000`, `set_waypoint_route`: `max_response_ms: 2000`

### 1.3: Localization and simulation services

- [ ] `pose_initializer.yaml` — `initialize`: `max_response_ms: 5000` (NDT alignment)
- [ ] `simple_planning_simulator.yaml` — `control_mode_request`: `max_response_ms: 100`,
  `set_pose`: `max_response_ms: 1000`

### 1.4: Low-priority services

- [ ] `vehicle_door_simulator.yaml` — `doors/command`, `doors/layout` (no strict timing)
- [ ] `aggregator.yaml` — `reset`, `set_initializing` (diagnostic admin)
