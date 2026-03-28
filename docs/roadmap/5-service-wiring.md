# Phase 5: Service Wiring

Add scope-level `services:` entries that wire `srv:` servers to `cli:` clients.
Currently most manifests have `srv:`/`cli:` on nodes but no `services:` at scope
level, so the `service-wiring` and `service-type` static rules can't fully verify.

## Criteria

- Every `cli:` endpoint has a matching `services:` entry with `server:` list
- Every `services:` entry has `type:` declared
- `service-wiring` rule produces 0 warnings
- `service-type` rule produces 0 errors/warnings

## Work Items

### 5.1: Mission planner (intra-scope wiring)

Route selector clients → mission planner servers, all in same container.

- [ ] `mission_planner.yaml` — add `services:` entries:
  ```yaml
  services:
    clear_route:
      type: autoware_planning_msgs/srv/ClearRoute
      server: [mission_planner/clear_route]
      client: [route_selector/clear_route]
    set_lanelet_route:
      type: autoware_planning_msgs/srv/SetLaneletRoute
      server: [mission_planner/set_lanelet_route]
      client: [route_selector/set_lanelet_route]
  ```

### 5.2: MRM handler (cross-scope wiring)

Handler clients call operator servers in different scopes. Cross-scope service
wiring requires the checker to look across manifest boundaries — this may need
import/export for services (not yet supported). Document the limitation.

- [ ] `mrm_handler.yaml` — document that `cli:` targets are in other scopes
- [ ] Evaluate whether `services:` can reference cross-scope endpoints or if
  this needs a new design
