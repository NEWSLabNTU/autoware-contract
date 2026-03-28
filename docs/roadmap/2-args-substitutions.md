# Phase 2: Args & Substitutions

Add `args:` declarations and `$(var ...)` substitutions to manifests so they
match their launch file context. Enables exact topic name resolution when
names depend on launch arguments.

## Criteria

- Every manifest with `$(var ...)` topic remappings in its launch file has
  matching `args:` declarations
- Default values match the launch file's `<arg default="..."/>`
- `$(var ...)` used in topic type, import endpoints, or other string fields
  where the actual value depends on launch args
- Source cited: launch file path + arg name

## Work Items

### 2.1: Motion planning (highest value — 2 variable topic names)

- [ ] `motion_planning.yaml` — add args:
  ```yaml
  args:
    input_objects_topic_name: /perception/object_recognition/objects
    input_pointcloud_topic_name: /perception/obstacle_segmentation/pointcloud
  ```
  Use `$(var ...)` in import comments or future import `topic:` field.

### 2.2: Behavior planning (4 variable topic names)

- [ ] `behavior_planning.yaml` — add args:
  ```yaml
  args:
    input_objects_topic_name: /perception/object_recognition/objects
    input_traffic_light_topic_name: /perception/traffic_light_recognition/traffic_signals
    input_vector_map_topic_name: /map/vector_map
    input_pointcloud_topic_name: /perception/obstacle_segmentation/pointcloud
  ```

### 2.3: Control (variable topic names + container config)

- [ ] `control.yaml` — add args:
  ```yaml
  args:
    use_multithread: "true"
    input_pointcloud_topic_name: /perception/obstacle_segmentation/pointcloud
    input_objects_topic_name: /perception/object_recognition/objects
  ```

### 2.4: Scenario selector (variable trajectory inputs)

- [ ] `scenario_selector.yaml` — add args:
  ```yaml
  args:
    input_lane_driving_trajectory: /planning/scenario_planning/lane_driving/trajectory
    input_parking_trajectory: /planning/scenario_planning/parking/trajectory
  ```

### 2.5: Remaining manifests with variable topics

- [ ] `simple_planning_simulator.yaml` — `motion_publish_mode`
- [ ] `multi_object_tracker.yaml` — input channel topic names
- [ ] `map_based_prediction.yaml` — traffic signal topic
