# Design Notes

Issues and observations discovered during manifest authoring. These feed back
into the manifest format design and checker tool improvements.

## 1. QoS Default — Resolved

`rclcpp::QoS(1)` defaults to **reliable/volatile/depth1** (from
`rmw_qos_profile_default`). This is well-defined — no ambiguity.
`InterProcessPollingSubscriber` is a subscription wrapper pattern, not a
different QoS profile — the underlying DDS QoS is still whatever the
constructor specifies.

Early manifests incorrectly marked planning pipeline topics as `best_effort`;
corrected to `reliable`. Only `SensorDataQoS()` (depth=5) is best_effort.

## 2. Variable Topic Names

Several nodes use `$(var input_pointcloud_topic_name)` and
`$(var input_objects_topic_name)` for topic remapping. These are resolved at
launch time from args. The manifest currently uses generic names like
`pointcloud` in imports — the actual resolved name depends on launch args.
`play_launch check` resolves these when given the launch file, but the manifest
alone doesn't capture the mapping.

## 3. Intra-Container Topics

Topics between composable nodes in the same container (e.g., `smoothed_path`
between elastic_band_smoother and path_optimizer) may use intra-process
communication, which bypasses DDS entirely. The QoS declaration in the manifest
still describes the DDS-level contract, but runtime graph monitoring won't see
intra-process messages on the DDS graph.

## 4. Service-Only Nodes — Resolved

Some nodes (e.g., pose_initializer) are primarily service-based — they don't
publish topics at a steady rate but respond to service calls. The manifest
format now supports `max_response_ms` on `srv:` and `cli:` endpoints
(Phase 1). ROS 2 has no native DDS mechanism for service deadlines, so
enforcement is runtime-only via interception.

## 5. Config-File Parameters Are Expanded in record.json

Some Autoware nodes are parameterized via **YAML config files** rather than
launch `<arg>` declarations. For example, `multi_object_tracker` gets its
input channel topics from a YAML file pointed to by `input_channels_path`.

Initially this seemed like a limitation — the manifest `args:` can capture
the config file path but not its contents. However, **the parser already
resolves these**: `record.json` contains the expanded parameters as scope
args (e.g., `input/detection01/objects = /perception/object_recognition/detection/objects`).
The manifest loader sees these in `scope.args` and can use them for `$(var ...)`
substitution.

This means the manifest can reference these values via `$(var ...)`.

**Decision (Option B)**: Manifest args should be declared as **required**
(no defaults) — record.json is the single source of truth for arg values.
The manifest declares *which* args it needs; the scope table provides the
values. This eliminates duplication and prevents drift between manifest
defaults and launch file defaults.

```yaml
args:
  input/detection01/objects:     # required — value from record.json scope
  input/detection01/channel:     # required
```

The only downside is manifests can't be validated standalone (without a
launch file). But `play_launch check` already requires a launch file, so
this is consistent with the current workflow.

## 6. `max_response_ms` Requires Source Traceability

**Decision**: Do not set `max_response_ms` unless the requirement can be
traced to a specific source:
- Autoware source code (timeout values, timer periods)
- Autoware design documents or online discussions
- Safety standards (e.g., ISO 26262 reaction time budgets)

If a service is believed to be safety-critical but no concrete requirement
exists in the source, leave a `# safety-critical — no documented requirement`
comment instead of inventing a number. Unsourced values create false
confidence — they look like requirements but are actually guesses.

**Consequence**: Phase 1 values (MRM 100ms, route 2000ms, NDT 5000ms) were
design targets without source traceability. They have been removed and
replaced with comments noting the safety relevance. Values will be added
back when:
1. A concrete requirement is found in Autoware source/docs, or
2. Runtime measurements via service call interception establish baselines

## 7. Condition Granularity Gap

Autoware's `motion_planning.launch.xml` conditionally enables velocity planner
**modules** (e.g., `launch_obstacle_stop_module`, `launch_obstacle_cruise_module`)
via `<let>` and conditional `<arg>` accumulation. However, these modules are all
loaded into the **same composable node** (`motion_velocity_planner`) — they're
plugin classes, not separate nodes.

The manifest `if:` / `unless:` system works at the node/topic level, not the
plugin level. A conditional module that changes the internal behavior of a
single node can't be expressed as `if:` on a node — the node always exists,
just with different plugins loaded.

For now, document module flags in `args:` comments but don't add `if:` on
the node itself. Phase 3 conditions are best suited for nodes/topics that
are truly conditionally present (e.g., `launch_collision_detector`
enabling/disabling a whole node in `control.launch.xml`).

**Finding from Phase 3**: Only `control.launch.xml` has real conditional
`<group if="...">` blocks for node-level inclusion. The 4 checker nodes
(control_validator, AEB, lane_departure_checker, collision_detector) got
`if:` conditions. All other "conditional" features in Autoware planning/
motion are plugin-level inside existing nodes — `if:` does not apply.

## 8. Conditional Topics Should Follow Conditional Nodes

When a node has `if:`, the topics that reference its endpoints should also
have `if:` with the same condition. Otherwise the checker will warn about
wiring to a non-existent endpoint when the condition is false.

Currently `control.yaml` does not add `if:` to the `predicted_trajectory`
topic (which references `lane_departure_checker` and AEB as subscribers).
When those nodes are filtered out, the topic's subscriber list points to
non-existent nodes. The checker's wiring rule may or may not catch this
depending on whether it validates subscriber endpoint existence.

This is a known gap — for now, we accept that conditional nodes may leave
dangling topic references. A future improvement would be to support `if:`
on individual entries in topic pub/sub lists, or to make the wiring rule
condition-aware.

## 9. Cross-Scope Service Wiring Not Supported

The manifest `services:` section wires `srv:` servers to `cli:` clients
**within a single scope**. Autoware's MRM system has cross-scope service
calls: `mrm_handler` (in its own scope) calls `operate` on operators in
separate scopes (`mrm_comfortable_stop_operator`, `mrm_emergency_stop_operator`).

The manifest format has no mechanism for cross-scope service wiring — there's
no import/export system for services like there is for topics. The
`service-wiring` rule will warn about unmatched `cli:` endpoints in this case.

**Options for future work**:
1. Add `service_imports:`/`service_exports:` analogous to topic imports/exports
2. Make the checker cross-scope aware (look across loaded manifests)
3. Accept the gap — cross-scope services are rare and the wiring can be
   verified at the parent scope level that includes both children

For now, option 3 is adopted. The limitation is documented in each affected
manifest file.
