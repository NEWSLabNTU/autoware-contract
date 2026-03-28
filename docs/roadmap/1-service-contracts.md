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

- [x] `mrm_handler.yaml` — 3 `cli:` endpoints: `max_response_ms: 100` (design target)
- [x] `mrm_comfortable_stop_operator.yaml` — `operate` server: `max_response_ms: 100`
- [x] `mrm_emergency_stop_operator.yaml` — `operate` server: `max_response_ms: 50`

### 1.2: Mission planning services

Route changes must complete before next planning cycle.

- [x] `mission_planner.yaml` — `clear_route`: 500, `set_lanelet_route`: 2000, `set_waypoint_route`: 2000

### 1.3: Localization and simulation services

- [x] `pose_initializer.yaml` — `initialize`: 5000 (NDT alignment)
- [x] `simple_planning_simulator.yaml` — `control_mode_request`: 100, `set_pose`: 1000

### 1.4: Low-priority services

- [x] `vehicle_door_simulator.yaml` — `doors/command`: 1000, `doors/layout`: 100
- [x] `aggregator.yaml` — `reset`: 500, `set_initializing`: 100
