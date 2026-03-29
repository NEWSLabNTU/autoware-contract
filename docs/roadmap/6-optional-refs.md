# Phase 6: Optional Endpoint Refs (`?` Suffix)

Add `?` suffix to all endpoint references that point to conditional nodes.
This is a machine-checkable marker — the `optional-ref` rule enforces:
- Refs to conditional nodes (`if:`/`unless:`) **must** have `?`
- Refs to unconditional nodes **must not** have `?`

## Criteria

- Every endpoint ref (in `topics:` pub/sub, `services:` server/client,
  `imports:`, `exports:`) to a conditional node has `?` suffix
- `optional-ref` rule produces 0 errors on all manifests
- Comments cite which condition the ref depends on

## Work Items

### 6.1: control.yaml — imports with conditional node refs

4 conditional nodes, ~16 endpoint refs in imports need `?`:

- [x] `control_validator` refs in imports (kinematic_state, measured_acceleration,
  operation_mode, reference_trajectory)
- [x] `autonomous_emergency_braking` refs in imports (velocity_status, imu,
  pointcloud, predicted_objects)
- [x] `lane_departure_checker` refs in imports (kinematic_state, operation_mode,
  vector_map, route, reference_trajectory)
- [x] `collision_detector` refs in imports (kinematic_state, operation_mode,
  pointcloud, predicted_objects)

### 6.2: Verify all other manifests

- [x] Scan all manifests for conditional nodes and verify their refs have `?`
  (currently only `control.yaml` has conditional nodes)
