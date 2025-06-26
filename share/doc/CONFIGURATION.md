# MicroUI Configuration Schema

This document describes the JSON Schema for MicroUI configuration files. The configuration can be written in JSON, YAML, or the legacy INI format.

## Schema Location

The JSON Schema is located at: `schemas/microui-config.schema.json`

## Supported Formats

### JSON

```json
{
  "version": "0.1.0",
  "client": {
    "mode": "window",
    "width": 1440,
    "height": 900
  },
  "server": {
    "mode": "console"
  }
}
```

### YAML

```yaml
version: "0.1.0"
client:
  mode: window
  width: 1440
  height: 900
server:
  mode: console
```

### Legacy INI (current microui.conf)

```ini
version 0.1.0

client.mode window
client.width 1440
client.height 900

server.mode console
```

## Configuration Sections

### Required Fields

- **version**: Semantic version string (e.g., "0.1.0")

### Client Configuration

Controls client-side rendering and window settings:

- **mode**: Rendering mode (`window`, `fullscreen`, `headless`, `console`)
- **width**: Window width in pixels (320-7680)
- **height**: Window height in pixels (240-4320)
- **title**: Window title string
- **resizable**: Whether window can be resized
- **vsync**: Enable vertical synchronization
- **fps_limit**: Maximum frames per second (30-240)

### Server Configuration

Controls server-side operation:

- **mode**: Server mode (`console`, `daemon`, `service`, `embedded`)
- **host**: Bind address (hostname/IP)
- **port**: Port number (1024-65535)
- **max_connections**: Maximum concurrent connections (1-10000)
- **timeout**: Connection timeout in seconds (1-3600)
- **workers**: Number of worker threads (1-32)

### Execution Configuration

Controls execution context behavior:

- **strategy**: Execution strategy (`sequential`, `parallel`, `race`, `merge`)
- **max_threads**: Maximum execution threads (1-64)
- **timeout**: Execution timeout in seconds (1-600)

### Logging Configuration

Controls logging behavior:

- **level**: Log level (`trace`, `debug`, `info`, `warn`, `error`, `fatal`)
- **output**: Output destination (`console`, `file`, `syslog`, `both`)
- **file**: Log file path
- **max_size**: Maximum log file size (e.g., "10MB", "1GB")
- **rotate**: Enable log rotation

## Examples

See the `examples/` directory for:

- `microui.minimal.json/yaml`: Minimal configuration matching current microui.conf
- `microui.config.json/yaml`: Complete configuration with defaults
- `microui.full.yaml`: Extended configuration with additional features

## Validation

You can validate your configuration files using any JSON Schema validator:

```bash
# Using ajv-cli
npx ajv-cli validate -s schemas/microui-config.schema.json -d examples/microui.config.json

# Using jsonschema (Python)
python -c "
import json, jsonschema
with open('schemas/microui-config.schema.json') as f: schema = json.load(f)
with open('examples/microui.config.json') as f: config = json.load(f)
jsonschema.validate(config, schema)
print('✅ Configuration is valid')
"
```

## Migration from INI Format

To migrate from the current INI format to JSON/YAML:

1. Convert dot-notation keys to nested objects:
   - `client.mode window` → `client: { mode: "window" }`
   - `client.width 1440` → `client: { width: 1440 }`

2. Add quotes around string values in JSON
3. Use proper boolean values instead of strings where applicable
4. Group related settings under appropriate sections

The schema is designed to be backward-compatible with the current configuration while allowing for future extensions.
