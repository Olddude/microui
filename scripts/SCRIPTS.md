# MicroUI Configuration Validation Scripts

This directory contains shell scripts for validating MicroUI configuration files using `jq` (for JSON) and `yq` (for YAML).

## Scripts

### `validate_json.sh`

Validates JSON configuration files against the MicroUI schema.

```bash
./scripts/validate_json.sh examples/microui.config.json
./scripts/validate_json.sh examples/*.json
```

### `validate_yaml.sh`

Validates YAML configuration files against the MicroUI schema.

```bash
./scripts/validate_yaml.sh examples/microui.config.yaml
./scripts/validate_yaml.sh examples/*.yaml
```

### `validate_config.sh`

Combined validator that handles both JSON and YAML files automatically.

```bash
# Validate all config files
./scripts/validate_config.sh examples/*

# Validate only JSON files
./scripts/validate_config.sh --json-only examples/*.json

# Validate only YAML files  
./scripts/validate_config.sh --yaml-only examples/*.yaml
```

## Dependencies

Make sure you have the required tools installed:

```bash
# Install jq for JSON processing
brew install jq

# Install yq for YAML processing (python-yq package includes yq v3.x)
brew install python-yq
```

## Schema Location

All scripts reference the schema file at:

```
schemas/microui-config.schema.json
```

## Validation Rules

The scripts validate:

1. **File format**: Valid JSON/YAML syntax
2. **Required fields**: `version` field must be present
3. **Version format**: Must follow semantic versioning (e.g., "1.0.0", "0.1.0-beta")
4. **Client mode**: If present, must be one of: `window`, `fullscreen`, `headless`, `console`
5. **Server mode**: If present, must be one of: `console`, `daemon`, `service`, `embedded`

## Example Output

```bash
$ ./scripts/validate_config.sh examples/microui.config.json

🔍 MicroUI Configuration Validator
==========================================

🔍 Validating: examples/microui.config.json
✅ Valid JSON configuration
   Version: 0.1.0
   Client mode: window
   Server mode: console

==========================================
Validated: 1 JSON + 0 YAML files
🎉 All configurations are valid!
```

## Error Examples

```bash
# Missing version field
❌ Missing required field 'version' in: config.json

# Invalid version format
❌ Invalid version format 'v1.0' in: config.json

# Invalid client mode
❌ Invalid client mode 'desktop' in: config.json

# Invalid JSON/YAML syntax
❌ Invalid JSON in: config.json
```

All scripts return exit code 0 on success and non-zero on validation failure, making them suitable for use in CI/CD pipelines.
