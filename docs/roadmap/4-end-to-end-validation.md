# Phase 4: End-to-End Validation

Run `play_launch check` against real Autoware launch files and verify all 36
manifests load, resolve, and pass static checks.

## Criteria

- `play_launch check --manifest-dir . autoware_launch planning_simulator.launch.xml`
  exits with 0 errors
- All 36 manifests are loaded (check log shows "Loaded 36 manifest(s)")
- No unresolved `$(var ...)` errors
- No required arg missing errors
- Documented in CI as a reproducible check

## Work Items

### 4.1: Basic validation

- [ ] Run `play_launch check --manifest-dir ~/repos/autoware-contract/ \
      autoware_launch planning_simulator.launch.xml`
- [ ] Fix any parse errors or type mismatches
- [ ] Document which scopes load manifests vs skip

### 4.2: Validation with non-default args

- [ ] Run with `vehicle_model:=sample_vehicle sensor_model:=sample_sensor_kit`
- [ ] Verify no new errors from different arg resolution

### 4.3: Investigate mismatches

- [ ] For any scope where manifest doesn't match: investigate root cause
- [ ] Document in [../notes.md](../notes.md)

### 4.4: CI automation

- [ ] Add `justfile` with `check` recipe:
  ```bash
  check:
      play_launch check --manifest-dir . \
          autoware_launch planning_simulator.launch.xml
  ```
- [ ] Document in README.md
