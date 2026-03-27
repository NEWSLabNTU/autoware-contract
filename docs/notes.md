# Design Notes

Issues and observations discovered during manifest authoring. These feed back
into the manifest format design and checker tool improvements.

## 1. QoS Default Ambiguity

`rclcpp::QoS(1)` defaults to `reliable` in ROS 2, but some Autoware nodes use
`InterProcessPollingSubscriber` which may behave differently. The manifest
format doesn't distinguish polling vs callback subscription patterns — both are
just `sub:`. Consider whether this matters for runtime monitoring.

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

## 4. Service-Only Nodes

Some nodes (e.g., pose_initializer) are primarily service-based — they don't
publish topics at a steady rate but respond to service calls. The manifest
format handles this via `srv:` declarations, but the timing/rate constraints
don't apply well to request-response patterns. Consider whether service
latency contracts are needed.
