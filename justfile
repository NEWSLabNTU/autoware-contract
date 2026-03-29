# Autoware Contract Manifests — validation recipes

play_launch := env("PLAY_LAUNCH", "play_launch")

# Check all manifests against Autoware planning_simulator
check:
    {{play_launch}} check --manifest-dir . \
        autoware_launch planning_simulator.launch.xml \
        map_path:=/tmp/dummy_map

# Check with explicit vehicle/sensor args
check-with-args:
    {{play_launch}} check --manifest-dir . \
        autoware_launch planning_simulator.launch.xml \
        map_path:=/tmp/dummy_map \
        vehicle_model:=sample_vehicle \
        sensor_model:=sample_sensor_kit
