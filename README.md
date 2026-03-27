# Autoware Contract Manifests

Per-launch-file manifest YAML files describing the expected communication graph
for Autoware planning_simulator. Used with `play_launch check` for static
contract verification.

## Usage

```bash
# Check all manifests against the Autoware launch tree
play_launch check --manifest-dir ~/repos/autoware-contract/ \
    autoware_launch planning_simulator.launch.xml

# With launch arguments
play_launch check --manifest-dir ~/repos/autoware-contract/ \
    autoware_launch planning_simulator.launch.xml \
    vehicle_model:=sample_vehicle sensor_model:=sample_sensor_kit
```

## Layout

```
<package_name>/<stem>.yaml
```

Where `<stem>` is the launch file name with `.launch.xml`/`.launch.py` stripped.
This matches play_launch's `resolve_manifest_path()` convention.

## Source

Autoware Universe 1.5.0 (`~/repos/autoware/1.5.0-ws/`).
Scope inventory: `play_launch/docs/roadmap/phase-31b-autoware_contract.md`.
