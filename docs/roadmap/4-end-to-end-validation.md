# Phase 4: End-to-End Validation

Run `play_launch check` against real Autoware launch files and verify all 36
manifests load, resolve, and pass static checks — including the new features
from Phases 1–3, 5–6.

## Prerequisites

- ROS 2 environment sourced with Autoware installed
- `play_launch` built with manifest support (Phase 31+32 features)
- `~/repos/autoware-contract/` manifests up to date

## Criteria

- `play_launch check --manifest-dir . autoware_launch planning_simulator.launch.xml`
  exits with 0 errors
- All 36 manifests are loaded (check log shows "Loaded 36 manifest(s)")
- No unresolved `$(var ...)` errors (args resolved from scope table)
- No required arg missing errors (7 manifests declare mandatory args)
- `if:`/`unless:` conditions correctly filter conditional nodes (control.yaml)
- `?` suffix refs correctly handled (dropped or stripped after filtering)
- `optional-ref` rule: 0 errors (all `?` refs match conditional nodes)
- `service-wiring` rule: 0 errors intra-scope; accepted warnings for
  cross-scope MRM handler clients
- `service-type` rule: 0 errors (all `services:` entries have types)

## Work Items

### 4.1: Basic validation

- [x] Run `play_launch check --manifest-dir ~/repos/autoware-contract/ \
      autoware_launch planning_simulator.launch.xml`
- [x] Fix any parse errors, type mismatches, or arg resolution failures
- [x] Document which scopes load manifests vs skip (expect 36 loaded, ~47 skipped)
- [x] Verify `?` suffix refs are correctly handled for control.yaml conditional nodes

### 4.2: Validation with non-default args

- [x] Run with `vehicle_model:=sample_vehicle sensor_model:=sample_sensor_kit`
- [x] Verify no new errors from different arg resolution
- [x] Test with a conditional flag flipped (e.g., add
  `launch_collision_detector:=false`) and verify the conditional node is
  filtered and its `?` refs are dropped

### 4.3: Investigate and fix mismatches

- [x] For each error/warning: investigate root cause
  - Required arg missing → add to manifest `args:` or fix arg name
  - Unresolved `$(var ...)` → arg not in scope table, check launch file
  - `optional-ref` error → missing or misplaced `?` suffix
  - `service-wiring` warning → cross-scope or missing `services:` entry
- [x] Document findings in [../notes.md](../notes.md)
- [x] Fix manifests and re-run until 0 errors

### 4.4: CI automation

- [x] Add `justfile` with recipes:
  ```just
  # Check all manifests against Autoware planning_simulator
  check:
      play_launch check --manifest-dir . \
          autoware_launch planning_simulator.launch.xml

  # Check with explicit args
  check-with-args:
      play_launch check --manifest-dir . \
          autoware_launch planning_simulator.launch.xml \
          vehicle_model:=sample_vehicle sensor_model:=sample_sensor_kit

  # Check JSON output (for CI parsing)
  check-json:
      play_launch check --manifest-dir . --format json \
          autoware_launch planning_simulator.launch.xml
  ```
- [x] Document in README.md under "CI / Validation" section
- [x] Add GitHub Actions workflow (optional — depends on Autoware availability in CI)
