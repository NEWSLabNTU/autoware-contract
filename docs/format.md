# Manifest Format

Each manifest YAML file describes the communication contract for one Autoware
launch file scope. The full format specification lives in the
[play_launch design docs](https://github.com/NEWSLabNTU/play_launch/blob/main/docs/design/launch-manifest.md);
this page covers the subset used in Autoware contracts.

## Top-Level Structure

```yaml
version: 1

nodes:       # node declarations (keyed by node name)
topics:      # topic declarations (keyed by topic name, relative to scope namespace)
services:    # service declarations (keyed by service name)
imports:     # endpoint groups consumed from outside this scope
exports:     # endpoint groups published to outside this scope
paths:       # causal path declarations at scope level
```

## Nodes

```yaml
nodes:
  node_name:
    sub:                          # subscribers
      topic_a:
        min_rate_hz: 10           # minimum expected rate
        state: true               # polled (read-latest), not causal
        required: true            # must receive at least once before operational
      topic_b: {}                 # no constraints
    pub:                          # publishers
      output:
        min_rate_hz: 30
    srv:                          # service servers
      my_service: {}
    cli:                          # service clients
      remote_service: {}
    paths:                        # causal paths through this node
      main:
        input: topic_a            # single endpoint or list
        output: [output]          # list of publisher endpoints
        max_latency_ms: 10
```

### Endpoint Properties

| Field | Type | Description |
|-------|------|-------------|
| `min_rate_hz` | float | Minimum expected publish/subscribe rate |
| `max_rate_hz` | float | Maximum expected rate |
| `jitter_ms` | float | Maximum timing jitter |
| `state` | bool | Subscriber reads latest value (not causal — breaks dataflow cycles) |
| `required` | bool | Must receive at least one message before the node is operational |

## Topics

```yaml
topics:
  control_cmd:
    type: autoware_control_msgs/msg/Control    # message type (required)
    pub: [controller/control_cmd]              # publisher endpoint refs (node/endpoint)
    sub: [validator/control_cmd]               # subscriber endpoint refs
    rate_hz: 30                                # expected rate
    qos:
      reliability: reliable                    # reliable | best_effort
      durability: transient_local              # volatile | transient_local
      depth: 1                                 # history depth
    drop: 2 / 100                              # max 2 drops per 100 messages (shorthand)
```

## Services

```yaml
services:
  initialize:
    type: autoware_localization_srvs/srv/Initialize
    server: [pose_initializer/initialize]
    client: []
```

## Imports / Exports

Groups of endpoints that cross scope boundaries:

```yaml
imports:
  odometry:                       # group name
    - controller/kinematic_state  # node/endpoint consumed from outside
    - validator/kinematic_state

exports:
  control_output:
    - controller/control_cmd      # node/endpoint published to outside
```

## Paths

Named causal paths (input → processing → output):

```yaml
paths:
  control:
    input: trajectory_input       # import group name or endpoint
    output: [control_output]      # export group name or endpoint list
    max_latency_ms: 15            # end-to-end latency budget
    max_age_ms: 200               # data freshness bound
    drop:
      max_count: 3 / 100          # max drops in window
      max_consecutive: 5          # max consecutive drops
```

Periodic (timer-driven) nodes use empty input:

```yaml
paths:
  periodic:
    input: []                     # no causal input — driven by timer
    output: [odometry]
    max_latency_ms: 5
```

## Comments

Every requirement should cite its source:

```yaml
    sub:
      trajectory:                    # /planning/trajectory — remap ~/input/reference_trajectory
        min_rate_hz: 10              # driven by upstream planner at 10 Hz
      operation_mode:                # /system/operation_mode/state — QoS(1).transient_local()
        state: true                  # InterProcessPollingSubscriber in controller_node.cpp line 118
        required: true
```
