# Configuration Templates

This directory contains template files for server, plugin, and datapack configurations. Templates use variable substitution to support different environments (dev, prod).

## Directory Structure

```
templates/
├── server/              # Server configuration templates
│   ├── server.properties.template
│   ├── bukkit.yml.template
│   ├── spigot.yml.template
│   ├── paper-global.yml.template
│   └── paper-world-defaults.yml.template
├── plugins/             # Plugin configuration templates
│   ├── BlueMap/
│   ├── DiscordSRV/
│   ├── Geyser-Spigot/
│   └── Floodgate/
└── datapacks/          # Datapack configurations (JSON)

```

## Variable Substitution

Templates support environment variable substitution using the syntax:
- `${VAR_NAME}` - Required variable, fails if not set
- `${VAR_NAME:-default}` - Optional variable with default value

### Available Variables

Variables are loaded from:
1. `.env` file in the project root
2. Environment-specific files: `.env.dev` or `.env.prod`
3. Shell environment variables

Common variables:
- `${SERVER_NAME}` - Server name
- `${SERVER_PORT}` - Server port (default: 25565)
- `${MAX_PLAYERS}` - Maximum players
- `${VIEW_DISTANCE}` - View distance
- `${SIMULATION_DISTANCE}` - Simulation distance
- `${DIFFICULTY}` - Game difficulty
- `${GAMEMODE}` - Default game mode
- `${MOTD}` - Message of the day
- `${DISCORD_WEBHOOK_URL}` - Discord webhook for notifications
- `${BLUEMAP_PORT}` - BlueMap web server port
- `${GEYSER_PORT}` - Geyser Bedrock port

## Usage

### Generate Configurations

```bash
# Generate configurations for development
./manage.sh generate-configs dev

# Generate configurations for production
./manage.sh generate-configs prod

# Generate specific plugin configs only
./manage.sh generate-configs dev --plugin BlueMap

# Force regenerate all configs
./manage.sh generate-configs prod --force
```

### Create New Templates

1. Copy an existing config file to the templates directory
2. Replace values with variables: `server-name=MyServer` → `server-name=${SERVER_NAME}`
3. Add variable defaults to `.env.example`
4. Test with `./manage.sh generate-configs dev`

### Custom Variables

Add custom variables to environment files:

```bash
# .env.dev
CUSTOM_SPAWN_RADIUS=100
ENABLE_EXPERIMENTAL_FEATURE=true

# .env.prod
CUSTOM_SPAWN_RADIUS=500
ENABLE_EXPERIMENTAL_FEATURE=false
```

Use in templates:
```yaml
spawn-radius: ${CUSTOM_SPAWN_RADIUS:-100}
experimental: ${ENABLE_EXPERIMENTAL_FEATURE:-false}
```

## Template Examples

### Server Properties
```properties
# server.properties.template
server-name=${SERVER_NAME}
server-port=${SERVER_PORT:-25565}
max-players=${MAX_PLAYERS:-20}
view-distance=${VIEW_DISTANCE:-10}
difficulty=${DIFFICULTY:-normal}
```

### Plugin Config (YAML)
```yaml
# config.yml.template
server:
  name: "${SERVER_NAME}"
  port: ${SERVER_PORT:-25565}
features:
  enabled: ${ENABLE_FEATURE:-true}
```

## Best Practices

1. **Version Control**: Commit templates, not generated configs
2. **Sensitive Data**: Never commit `.env` files, only `.env.example`
3. **Defaults**: Always provide sensible defaults in templates
4. **Documentation**: Comment complex variables in templates
5. **Validation**: Test generated configs before deploying

## Troubleshooting

**Missing variables:**
```
Error: Required variable SERVER_NAME is not set
```
Solution: Add the variable to your `.env` file

**Invalid syntax:**
```
Error: Invalid template syntax at line 42
```
Solution: Check for unclosed `${}` or special characters

**Permission errors:**
```
Error: Cannot write to config/ directory
```
Solution: Check file permissions and ownership
