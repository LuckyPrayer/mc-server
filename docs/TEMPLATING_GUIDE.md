# Configuration Templating System Guide

This guide explains how to use the configuration templating system for your Minecraft server, plugins, and datapacks.

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Template Syntax](#template-syntax)
- [Environment Variables](#environment-variables)
- [Creating Templates](#creating-templates)
- [Runtime Processing](#runtime-processing)
- [Local Testing](#local-testing)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

The templating system allows you to:
- **Version control** your configurations without hardcoding values
- **Separate** development and production settings cleanly
- **Automate** configuration generation at container startup
- **Manage** multiple environments from a single template set
- **Reduce errors** by using validated templates

### Benefits

✅ **No more manual config editing** - Change environment variables, not files  
✅ **Environment-specific** - Different values for dev vs prod automatically  
✅ **Fresh configs every start** - Templates processed at container runtime  
✅ **Git-friendly** - Commit templates, not generated configs  
✅ **Plugin support** - Pre-configured templates for BlueMap, DiscordSRV, Geyser, Floodgate

---

## Quick Start

### 1. Set Up Environment Variables

Copy the example environment files:

```bash
# Base environment file
cp .env.example .env

# Development environment
cp .env.dev.example .env.dev

# Production environment
cp .env.prod.example .env.prod
```

Edit these files with your specific values:

```bash
# Edit base settings
nano .env

# Edit development settings
nano .env.dev

# Edit production settings
nano .env.prod
```

### 2. Configure Important Variables

At minimum, set these in `.env.prod`:

```bash
# Required for production
RCON_PASSWORD=<your-strong-password>
SERVER_NAME=My Awesome Server
MOTD=Welcome to my server!

# For Discord integration
DISCORD_BOT_TOKEN=<your-bot-token>
DISCORD_GUILD_ID=<your-guild-id>
DISCORD_CHAT_CHANNEL_ID=<your-channel-id>

# For BlueMap
BLUEMAP_ACCEPT_DOWNLOAD=true
```

### 3. Test Template Generation Locally

Generate configs to verify your templates:

```bash
# Generate development configs
./generate-configs.sh dev

# Generate production configs
./generate-configs.sh prod

# Or use the management script
./manage.sh generate-configs
```

### 4. Start Your Server

Templates are automatically processed when the container starts:

```bash
# Development
docker-compose -f docker-compose.dev.yml up -d

# Production
docker-compose -f docker-compose.prod.yml up -d
```

**That's it!** Configurations are generated automatically from templates using your environment variables.

---

## How It Works

### Runtime Processing Flow

```
Container Starts
      ↓
 Entrypoint Script (/entrypoint.sh)
      ↓
 Loads Environment Variables
  (.env, .env.dev or .env.prod)
      ↓
 Processes Templates (/templates/)
      ↓
 Generates Configs (/data/)
      ↓
 Starts Minecraft Server
```

### Directory Structure

```
mc-server/
├── templates/                    # Template files (committed to git)
│   ├── server/                   # Server configuration templates
│   │   ├── server.properties.template
│   │   ├── bukkit.yml.template
│   │   ├── spigot.yml.template
│   │   ├── paper-global.yml.template
│   │   └── paper-world-defaults.yml.template
│   └── plugins/                  # Plugin configuration templates
│       ├── BlueMap/
│       │   └── core.conf.template
│       ├── DiscordSRV/
│       │   └── config.yml.template
│       ├── Geyser-Spigot/
│       │   └── config.yml.template
│       └── Floodgate/
│           └── config.yml.template
├── config/                       # Generated server configs (not committed)
├── docs/                         # Documentation (committed)
├── .env                          # Base environment (not committed)
├── .env.dev                      # Dev environment (not committed)
├── .env.prod                     # Prod environment (not committed)
├── .env.example                  # Template for .env (committed)
├── .env.dev.example              # Template for dev (committed)
├── .env.prod.example             # Template for prod (committed)
└── generate-configs.sh           # Local config generator script
```

---

## Template Syntax

Templates use environment variable substitution with the `${VARIABLE}` syntax.

### Basic Syntax

```properties
# server.properties.template
server-name=${SERVER_NAME}
max-players=${MAX_PLAYERS}
```

With environment variables:
```bash
SERVER_NAME="My Server"
MAX_PLAYERS=20
```

Generates:
```properties
# server.properties
server-name=My Server
max-players=20
```

### Default Values

Provide fallback values using `${VARIABLE:-default}`:

```properties
view-distance=${VIEW_DISTANCE:-10}
difficulty=${DIFFICULTY:-normal}
```

If `VIEW_DISTANCE` is not set, it defaults to `10`.

### Required Variables

Use `${VARIABLE:?error message}` for required variables:

```yaml
bot-token: "${DISCORD_BOT_TOKEN:?Discord bot token is required}"
```

If `DISCORD_BOT_TOKEN` is not set, an error is raised.

### Nested Variables

You can reference other variables:

```bash
# In .env
SERVER_NAME="My Server"
MOTD="${SERVER_NAME} - Welcome!"
```

### YAML Strings

Wrap variables in quotes for YAML strings:

```yaml
server:
  name: "${SERVER_NAME}"
  motd: "${MOTD}"
```

### Comments

Comments in templates are preserved:

```properties
# This is a comment explaining the setting
max-players=${MAX_PLAYERS:-20}
```

---

## Environment Variables

### Variable Loading Order

Variables are loaded in this order (later overrides earlier):

1. System environment variables
2. `.env` (base settings)
3. `.env.dev` or `.env.prod` (environment-specific)
4. Docker Compose environment section
5. Docker run `-e` flags

### Available Variables

See the complete list in `.env.example`. Key variables include:

#### Server Identity
- `SERVER_NAME` - Server name displayed everywhere
- `MOTD` - Message of the day
- `SERVER_IP` - Public IP/domain for connections
- `SERVER_WEBSITE` - Website URL

#### Gameplay
- `GAMEMODE` - survival, creative, adventure, spectator
- `DIFFICULTY` - peaceful, easy, normal, hard
- `PVP` - true/false
- `MAX_PLAYERS` - Maximum player count
- `ONLINE_MODE` - true/false (require Mojang authentication)

#### World
- `LEVEL_NAME` - World folder name
- `LEVEL_SEED` - World generation seed
- `VIEW_DISTANCE` - Chunk view distance (2-32)
- `SIMULATION_DISTANCE` - Tick distance (2-32)

#### Security
- `RCON_PASSWORD` - **Required for production**
- `WHITELIST_ENABLED` - true/false
- `ENFORCE_WHITELIST` - true/false

#### Plugin-Specific

**BlueMap:**
- `BLUEMAP_PORT` - Web interface port
- `BLUEMAP_ACCEPT_DOWNLOAD` - Accept EULA (true/false)
- `BLUEMAP_RENDER_ON_START` - Render map on startup

**DiscordSRV:**
- `DISCORD_BOT_TOKEN` - **Required for Discord**
- `DISCORD_GUILD_ID` - Discord server ID
- `DISCORD_CHAT_CHANNEL_ID` - Chat channel ID

**Geyser:**
- `GEYSER_PORT` - Bedrock client port (default: 19132)
- `GEYSER_AUTH_TYPE` - floodgate, online, or offline

**Floodgate:**
- `FLOODGATE_XBOX_AUTH` - Require Xbox authentication
- `FLOODGATE_USERNAME_PREFIX` - Prefix for Bedrock players

---

## Creating Templates

### From Existing Config

1. Copy your working config to templates:
   ```bash
   cp config/server.properties templates/server/server.properties.template
   ```

2. Replace hardcoded values with variables:
   ```diff
   - server-name=My Cool Server
   + server-name=${SERVER_NAME}
   
   - max-players=20
   + max-players=${MAX_PLAYERS:-20}
   ```

3. Add the variable to `.env.example`:
   ```bash
   SERVER_NAME=My Minecraft Server
   MAX_PLAYERS=20
   ```

4. Test locally:
   ```bash
   ./generate-configs.sh dev --dry-run
   ```

### Template Best Practices

✅ **Always provide defaults** for optional settings:
```properties
view-distance=${VIEW_DISTANCE:-10}
```

✅ **Require critical values** in production:
```yaml
password: "${RCON_PASSWORD:?RCON password must be set}"
```

✅ **Document complex variables** in templates:
```properties
# Set to -1 to disable watchdog, or milliseconds to wait
max-tick-time=${MAX_TICK_TIME:-60000}
```

✅ **Use descriptive variable names**:
```bash
# Good
BLUEMAP_RENDER_ON_START=false

# Bad
BR=false
```

✅ **Group related variables** in .env files:
```bash
# === BlueMap Configuration ===
BLUEMAP_PORT=8100
BLUEMAP_ACCEPT_DOWNLOAD=true
BLUEMAP_RENDER_ON_START=false
```

---

## Runtime Processing

Templates are processed automatically when containers start via the custom entrypoint script.

### Entrypoint Workflow

The `/entrypoint.sh` script:

1. **Checks** for `/templates/` directory
2. **Processes** all `*.template` files
3. **Generates** configs in `/data/` (server) and `/data/plugins/` (plugins)
4. **Starts** the Minecraft server

### Log Output

When the container starts, you'll see:

```
======================================
Minecraft Server - Template Processor
======================================

Found templates directory, processing templates...

Processing server configuration templates...
Processing: server.properties.template -> /data/server.properties
  ✓ Generated successfully
Processing: bukkit.yml.template -> /data/bukkit.yml
  ✓ Generated successfully

Processing plugin configuration templates...
Processing: core.conf.template -> /data/plugins/BlueMap/core.conf
  ✓ Generated successfully

✓ Template processing complete!

======================================
Starting Minecraft Server...
======================================
```

### Overriding Runtime Behavior

You can skip template processing by not including templates in the image:

```dockerfile
# In custom Dockerfile - don't copy templates
# COPY templates/ /templates/  # Commented out
```

Or override the entrypoint:

```yaml
# In docker-compose.yml
services:
  minecraft:
    entrypoint: ["/start"]  # Skip template processing
```

---

## Local Testing

### Generate Without Docker

Test template generation locally:

```bash
# See what would be generated
./generate-configs.sh dev --dry-run

# Generate development configs
./generate-configs.sh dev

# Generate production configs
./generate-configs.sh prod

# Generate only server configs
./generate-configs.sh dev --server-only

# Generate only BlueMap plugin config
./generate-configs.sh prod --plugin BlueMap

# Force overwrite existing files
./generate-configs.sh prod --force
```

### Validate Generated Configs

After generation, review the files:

```bash
# Check server config
cat config/server.properties

# Check plugin config
docker exec minecraft-server-dev cat /data/plugins/BlueMap/core.conf

# Look for unsubstituted variables
grep '\${' config/*
```

### Use Management Script

The management script provides a guided interface:

```bash
./manage.sh generate-configs
# Prompts for environment (dev/prod)
# Generates all configurations
```

---

## Best Practices

### Security

🔒 **Never commit `.env` files** - Only commit `.env.example`  
🔒 **Use strong passwords** - Generate with `openssl rand -base64 32`  
🔒 **Require passwords in prod** - Use `${VAR:?error}` syntax  
🔒 **Rotate secrets regularly** - Update `.env` and restart

### Development

💡 **Use `.env.dev` for local testing** - Separate from production  
💡 **Keep defaults permissive** - Make development easier  
💡 **Enable debug mode** - Set `DEBUG=true` in dev  
💡 **Use offline mode** - Allow cracked clients for testing

### Production

🚀 **Review all settings** before deploying  
🚀 **Test in dev first** - Verify templates work  
🚀 **Monitor first start** - Check template processing logs  
🚀 **Backup .env files** - Securely store configuration  
🚀 **Document custom variables** - Help your team

### Version Control

📝 **Commit templates** - Track configuration changes  
📝 **Don't commit generated configs** - They're in `.gitignore`  
📝 **Update `.env.example`** - Document all variables  
📝 **Use meaningful commits** - "Add Discord webhook support"

---

## Troubleshooting

### Templates Not Processing

**Problem:** Configurations aren't generated on container start

**Solutions:**
1. Check if templates directory exists in container:
   ```bash
   docker exec minecraft-server-dev ls -la /templates
   ```

2. Verify entrypoint script is executable:
   ```bash
   docker exec minecraft-server-dev ls -la /entrypoint.sh
   ```

3. Check container logs for errors:
   ```bash
   docker logs minecraft-server-dev
   ```

### Variable Not Substituted

**Problem:** Config shows `${VARIABLE}` instead of the value

**Solutions:**
1. Check variable is set in environment:
   ```bash
   docker exec minecraft-server-dev printenv | grep VARIABLE
   ```

2. Verify .env file is loaded:
   ```yaml
   # In docker-compose.yml
   services:
     minecraft:
       env_file:
         - .env
         - .env.dev
   ```

3. Check for typos in variable name

### Missing Required Variable

**Problem:** Container fails to start with "variable must be set"

**Solution:**
```bash
# Add the variable to your .env file
echo "MISSING_VARIABLE=value" >> .env.prod
```

### Template Syntax Errors

**Problem:** Generated config is malformed

**Solutions:**
1. Validate template syntax:
   ```bash
   # Check for unmatched braces
   grep -E '\$\{[^}]*$' templates/**/*.template
   ```

2. Test locally first:
   ```bash
   ./generate-configs.sh dev --dry-run
   ```

3. Check quotes in YAML templates:
   ```yaml
   # Wrong - missing quotes
   name: ${SERVER_NAME}
   
   # Right - with quotes
   name: "${SERVER_NAME}"
   ```

### Permission Errors

**Problem:** "Permission denied" when writing configs

**Solution:**
```bash
# Fix permissions on data directory
chown -R 1000:1000 data-dev/ data-prod/
```

### envsubst Not Found

**Problem:** Template processing falls back to basic substitution

**Solution:** The entrypoint script has a fallback using `perl`. If you want `envsubst`:

```dockerfile
# In your Dockerfile
RUN apt-get update && apt-get install -y gettext-base && rm -rf /var/lib/apt/lists/*
```

---

## Advanced Topics

### Custom Template Locations

Override where templates are loaded from:

```yaml
# docker-compose.yml
services:
  minecraft:
    volumes:
      - ./custom-templates:/templates
```

### Conditional Configuration

Use environment variables to enable/disable features:

```properties
# In template
${ENABLE_FEATURE:+feature-enabled=true}
```

### Multi-Environment Deployment

Structure for multiple environments:

```
.env.dev
.env.staging
.env.prod
```

Build for specific environment:

```bash
./build.sh --env staging
docker-compose -f docker-compose.staging.yml up -d
```

### Integration with CI/CD

```yaml
# .github/workflows/deploy.yml
- name: Generate production configs
  run: |
    ./generate-configs.sh prod --force
  env:
    SERVER_NAME: ${{ secrets.SERVER_NAME }}
    RCON_PASSWORD: ${{ secrets.RCON_PASSWORD }}
```

---

## Examples

### Example 1: Simple Server

**.env.prod:**
```bash
SERVER_NAME=Survival Server
MAX_PLAYERS=20
DIFFICULTY=hard
GAMEMODE=survival
RCON_PASSWORD=super-secret-password
```

**Result:** Basic survival server with 20 players, hard difficulty.

### Example 2: Creative Server with BlueMap

**.env.dev:**
```bash
SERVER_NAME=[CREATIVE] Build Server
GAMEMODE=creative
DIFFICULTY=peaceful
PVP=false
ALLOW_FLIGHT=true
BLUEMAP_ACCEPT_DOWNLOAD=true
BLUEMAP_PORT=8100
BLUEMAP_RENDER_ON_START=true
```

**Result:** Creative server with map accessible at http://localhost:8100

### Example 3: Production with Discord

**.env.prod:**
```bash
SERVER_NAME=Community Server
DISCORD_BOT_TOKEN=your_token_here
DISCORD_GUILD_ID=123456789
DISCORD_CHAT_CHANNEL_ID=987654321
DISCORD_USE_WEBHOOK=true
ONLINE_MODE=true
WHITELIST_ENABLED=true
ENFORCE_WHITELIST=true
RCON_PASSWORD=very-strong-password
```

**Result:** Production server with Discord chat integration and whitelist.

---

## Support

For issues or questions:

1. Check this guide
2. Review [templates/README.md](templates/README.md)
3. Check logs: `./manage.sh logs`
4. Run troubleshoot script: `./troubleshoot.sh`
5. Test locally: `./generate-configs.sh dev --dry-run`

---

**Last Updated:** November 29, 2025  
**Version:** 1.0
