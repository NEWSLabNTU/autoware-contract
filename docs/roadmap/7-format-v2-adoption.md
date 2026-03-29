# Phase 7: Manifest Format v2 Adoption

Adopt new manifest format features from play_launch Phase 33 in the
Autoware contract manifests.

Depends on: play_launch Phase 33 implementation.

## Work Items

### 7.1: Add arg types to manifests

After play_launch 33.3 (arg type declarations):

- [ ] `control.yaml` — add `type: bool` to 4 launch flags
  (`launch_control_validator`, `launch_autonomous_emergency_braking`,
  `launch_lane_departure_checker`, `launch_collision_detector`)
- [ ] Other manifests with boolean launch flags — add `type: bool`
- [ ] Run satisfiability check on all manifests

### 7.2: Migrate to unified scope interface

After play_launch 33.2 (unified scope interface):

- [ ] Replace `imports:`/`exports:` with top-level `pub:`/`sub:`/`srv:`/`cli:`
  on all 36 manifests
- [ ] Add `srv:` and `cli:` scope-level groups for service endpoints
  (currently in `services:` entries or undeclared)
- [ ] Verify `just check` still passes

### 7.3: Add missing args after parser fix

After play_launch 33.1 (parser records all resolved args):

- [ ] `behavior_planning.yaml` — re-add `input_traffic_light_topic_name`
  and `input_vector_map_topic_name` (now in scope.args)
- [ ] Audit all manifests for args that were skipped due to the parser bug

### 7.4: Satisfiability validation

After play_launch 33.5 (satisfiability checking):

- [ ] Run satisfiability check on `control.yaml` (4 boolean flags = 16 configs)
- [ ] Verify variant-completeness: no arg combination creates dangling entities
- [ ] Fix any discovered issues
- [ ] Add `just check-sat` recipe to justfile
