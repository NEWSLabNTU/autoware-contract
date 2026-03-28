# Phase 1: Service Contracts

Add `max_response_ms` to service endpoints where requirements exist in
Autoware source, design docs, or safety standards.

**Status**: On hold — service endpoints have safety/admin comments but no
concrete `max_response_ms` values. Values will be added when traceable
requirements are found. See [../notes.md](../notes.md) Note 6.

## Criteria

- `max_response_ms` only added when the requirement can be traced to a
  specific source (Autoware code, design docs, safety standards)
- If a service is safety-critical but has no documented requirement,
  leave a `# safety-critical — no documented requirement` comment
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
