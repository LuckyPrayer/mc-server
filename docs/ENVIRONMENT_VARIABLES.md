# Environment Variables Reference

Complete reference for all environment variables used in the Minecraft server configuration templates.

**Last Updated**: December 1, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Core Server Settings](#core-server-settings)
3. [Discord Integration (DiscordSRV)](#discord-integration-discordsrv)
4. [Bedrock Edition Support (Geyser)](#bedrock-edition-support-geyser)
5. [Floodgate](#floodgate)
6. [Web Maps (BlueMap)](#web-maps-bluemap)
7. [Quick Start Examples](#quick-start-examples)
8. [Advanced Configuration](#advanced-configuration)

---

## Overview

### How It Works

Environment variables are loaded in this order:

1. **Defaults files** (`/defaults/*.env`) - Loaded conditionally based on installed plugins
2. **Docker Compose** (`.env` or `docker-compose.yml`) - User-provided overrides
3. **Runtime exports** - Shell environment at container start

### Default Files Structure

```
defaults/
├── core.env        # Always loaded - essential server settings
├── discord.env     # Loaded if /templates/plugins/DiscordSRV exists
├── geyser.env      # Loaded if /templates/plugins/Geyser-Spigot exists
├── floodgate.env   # Loaded if /templates/plugins/Floodgate exists
└── bluemap.env     # Loaded if /templates/plugins/BlueMap exists
```

### Variable Priority

**Higher priority overrides lower:**

1. ⭐ Shell environment (manual export)
2. 🐳 Docker Compose environment section
3. 📄 Docker Compose .env file
4. 🔧 Defaults files (`/defaults/*.env`)

### Required vs Optional

- ✅ **REQUIRED** - Must be set for feature to work
- 🔧 **OPTIONAL** - Has a sensible default, override if needed
- 🎨 **COSMETIC** - Only affects appearance/messages

---

## Core Server Settings

**File**: `defaults/core.env`  
**Loaded**: Always

### Essential Settings

#### GAMEMODE
- **Type**: String
- **Default**: `survival`
- **Options**: `survival`, `creative`, `adventure`, `spectator`
- **Description**: Default game mode for new players

#### DIFFICULTY
- **Type**: String
- **Default**: `normal`
- **Options**: `peaceful`, `easy`, `normal`, `hard`
- **Description**: Game difficulty level

#### MAX_PLAYERS
- **Type**: Integer
- **Default**: `20`
- **Range**: 1-∞
- **Description**: Maximum concurrent players

#### VIEW_DISTANCE
- **Type**: Integer
- **Default**: `10`
- **Range**: 3-32
- **Description**: Render distance in chunks (affects server load)

#### SIMULATION_DISTANCE
- **Type**: Integer
- **Default**: `10`
- **Range**: 3-32
- **Description**: Tick distance for entities/redstone

### Access Control

#### ONLINE_MODE
- **Type**: Boolean
- **Default**: `true`
- **Description**: Require Mojang authentication
- **Note**: Set to `false` for LAN or testing

#### WHITELIST_ENABLED
- **Type**: Boolean
- **Default**: `false`
- **Description**: Enable whitelist system
- **Note**: Players must be added with `/whitelist add <player>`

#### ENFORCE_WHITELIST
- **Type**: Boolean
- **Default**: `false`
- **Description**: Kick non-whitelisted players immediately
- **Note**: Requires `WHITELIST_ENABLED=true`

#### WHITELIST_MESSAGE
- **Type**: String
- **Default**: `You are not whitelisted on this server!`
- **Description**: Message shown to non-whitelisted players

### World Settings

#### LEVEL_NAME
- **Type**: String
- **Default**: `world`
- **Description**: World folder name

#### LEVEL_TYPE
- **Type**: String
- **Default**: `minecraft:normal`
- **Options**: `minecraft:normal`, `minecraft:flat`, `minecraft:large_biomes`, `minecraft:amplified`
- **Description**: World generation type

#### LEVEL_SEED
- **Type**: String
- **Default**: `` (empty = random)
- **Description**: World seed for generation

#### SPAWN_PROTECTION
- **Type**: Integer
- **Default**: `16`
- **Range**: 0-∞ (0 = disabled)
- **Description**: Radius around spawn where only ops can build

### RCON (Remote Console)

#### ENABLE_RCON
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enable remote console for administration

#### RCON_PORT
- **Type**: Integer
- **Default**: `25575`
- **Description**: RCON connection port

#### RCON_PASSWORD
- **Type**: String
- **Default**: `minecraft`
- **⚠️ SECURITY**: Change this in production!
- **Description**: RCON authentication password

### Network Settings

#### SERVER_PORT
- **Type**: Integer
- **Default**: `25565`
- **Description**: Minecraft server port (TCP)

#### MOTD
- **Type**: String
- **Default**: `A Minecraft Server`
- **Description**: Message of the Day shown in server list

---

## Discord Integration (DiscordSRV)

**File**: `defaults/discord.env`  
**Loaded**: Only if `/templates/plugins/DiscordSRV` exists  
**Documentation**: https://github.com/DiscordSRV/DiscordSRV/wiki

### Required Configuration

#### DISCORD_BOT_TOKEN ✅
- **Type**: String
- **Default**: `` (empty - must be set!)
- **Description**: Bot token from Discord Developer Portal
- **How to get**:
  1. Go to https://discord.com/developers/applications
  2. Create application → Bot → Copy token
- **Example**: `DISCORD_BOT_TOKEN=MTAyMz...your-token...XYZ`

#### DISCORD_CHAT_CHANNEL_ID ✅
- **Type**: String (Discord Snowflake ID)
- **Default**: `` (empty - must be set!)
- **Description**: Channel ID for in-game chat relay
- **How to get**: Enable Developer Mode in Discord → Right-click channel → Copy ID

#### DISCORD_CONSOLE_CHANNEL_ID ✅
- **Type**: String (Discord Snowflake ID)
- **Default**: `` (empty - must be set!)
- **Description**: Channel ID for server console logs

### Bot Presence

#### DISCORD_ENABLE_PRESENCE
- **Type**: Boolean
- **Default**: `false`
- **Description**: Update bot status with player count

#### DISCORD_GAME_STATUS
- **Type**: String
- **Default**: `Minecraft`
- **Description**: Game shown in bot status

#### DISCORD_ONLINE_STATUS
- **Type**: String
- **Default**: `ONLINE`
- **Options**: `ONLINE`, `IDLE`, `DO_NOT_DISTURB`, `INVISIBLE`
- **Description**: Bot's Discord status

### Chat Relay

#### DISCORD_CHAT_MC_TO_DISCORD
- **Type**: Boolean
- **Default**: `true`
- **Description**: Send Minecraft chat to Discord

#### DISCORD_CHAT_DISCORD_TO_MC
- **Type**: Boolean
- **Default**: `true`
- **Description**: Send Discord messages to Minecraft

#### DISCORD_CHAT_REQUIRE_LINKED
- **Type**: Boolean
- **Default**: `false`
- **Description**: Only relay from linked Discord accounts

#### DISCORD_CHAT_BLOCK_BOTS
- **Type**: Boolean
- **Default**: `true`
- **Description**: Ignore messages from other bots

### Console Commands

#### DISCORD_CHAT_CONSOLE_COMMANDS_ENABLED
- **Type**: Boolean
- **Default**: `false`
- **⚠️ SECURITY**: Only enable for trusted admins
- **Description**: Allow running server commands from Discord

#### DISCORD_CHAT_CONSOLE_PREFIX
- **Type**: String
- **Default**: `!c`
- **Description**: Command prefix (e.g., `!c stop`)

#### DISCORD_CHAT_CONSOLE_ROLES
- **Type**: String (comma-separated)
- **Default**: `Admin`
- **Description**: Discord roles allowed to run commands

### Account Linking

#### DISCORD_LINKED_ROLE_ID
- **Type**: String (Discord Role ID)
- **Default**: `` (empty = disabled)
- **Description**: Role given to linked accounts

#### DISCORD_ALLOW_RELINK
- **Type**: Boolean
- **Default**: `false`
- **Description**: Allow users to change linked account

---

## Bedrock Edition Support (Geyser)

**File**: `defaults/geyser.env`  
**Loaded**: Only if `/templates/plugins/Geyser-Spigot` exists  
**Documentation**: https://wiki.geysermc.org/geyser/

### Network Configuration

#### GEYSER_PORT
- **Type**: Integer
- **Default**: `19132`
- **Protocol**: UDP
- **Description**: Bedrock Edition connection port
- **Note**: Must be exposed in Docker

#### GEYSER_REMOTE_ADDRESS
- **Type**: String
- **Default**: `auto`
- **Description**: Java server address (`auto` = localhost)

#### GEYSER_REMOTE_PORT
- **Type**: Integer
- **Default**: `25565`
- **Description**: Java server port to connect to

### Authentication

#### GEYSER_AUTH_TYPE
- **Type**: String
- **Default**: `online`
- **Options**: `online`, `offline`, `floodgate`
- **Description**: Authentication method
  - `online`: Bedrock players need Java accounts
  - `offline`: No authentication (insecure)
  - `floodgate`: Bedrock-only authentication

### MOTD (Bedrock)

#### GEYSER_MOTD1
- **Type**: String
- **Default**: `Geyser`
- **Description**: First line of Bedrock MOTD

#### GEYSER_MOTD2
- **Type**: String
- **Default**: `Another Geyser server.`
- **Description**: Second line of Bedrock MOTD

#### GEYSER_PASSTHROUGH_MOTD
- **Type**: Boolean
- **Default**: `true`
- **Description**: Use Java server's MOTD instead

### Performance

#### GEYSER_COMPRESSION_LEVEL
- **Type**: Integer
- **Default**: `6`
- **Range**: 1-9
- **Description**: Network compression (higher = more CPU, less bandwidth)

---

## Floodgate

**File**: `defaults/floodgate.env`  
**Loaded**: Only if `/templates/plugins/Floodgate` exists  
**Documentation**: https://wiki.geysermc.org/floodgate/

### Configuration

#### FLOODGATE_USERNAME_PREFIX
- **Type**: String
- **Default**: `.`
- **Description**: Prefix for Bedrock usernames
- **Example**: Bedrock player "Steve" appears as ".Steve"

#### FLOODGATE_REPLACE_SPACES
- **Type**: Boolean
- **Default**: `true`
- **Description**: Replace spaces in usernames with underscores

#### FLOODGATE_ENABLED
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enable Floodgate functionality

---

## Web Maps (BlueMap)

**File**: `defaults/bluemap.env`  
**Loaded**: Only if `/templates/plugins/BlueMap` exists  
**Documentation**: https://bluemap.bluecolored.de/wiki/

### Core Settings

#### BLUEMAP_ACCEPT_DOWNLOAD
- **Type**: Boolean
- **Default**: `true`
- **Description**: Accept BlueMap's download terms (required)

#### BLUEMAP_WEBSERVER_ENABLED
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enable built-in web server

#### BLUEMAP_PORT
- **Type**: Integer
- **Default**: `8100`
- **Protocol**: HTTP
- **Description**: Web interface port
- **Access**: `http://server-ip:8100`

### Rendering

#### BLUEMAP_RENDER_THREADS
- **Type**: Integer
- **Default**: `0` (auto)
- **Description**: Rendering threads (0 = CPU cores - 2)

#### BLUEMAP_HIRES_DEFAULT
- **Type**: Float
- **Default**: `0.5`
- **Description**: High-resolution tile quality (blocks per pixel)

#### BLUEMAP_LOWRES_DEFAULT
- **Type**: Integer
- **Default**: `4`
- **Description**: Low-resolution tile quality

### Web Interface

#### BLUEMAP_WEBAPP_ENABLED
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enable web application

#### BLUEMAP_DEFAULT_FLAT_VIEW
- **Type**: String
- **Default**: `topdown`
- **Options**: `topdown`, `flat`, `free`
- **Description**: Default camera view

---

## Quick Start Examples

### Minimal Vanilla Server

```env
# .env file
GAMEMODE=survival
DIFFICULTY=normal
MAX_PLAYERS=10
```

### Creative Building Server

```env
GAMEMODE=creative
DIFFICULTY=peaceful
ALLOW_FLIGHT=true
SPAWN_MONSTERS=false
MAX_PLAYERS=20
```

### Whitelisted Survival Server

```env
GAMEMODE=survival
DIFFICULTY=hard
WHITELIST_ENABLED=true
ENFORCE_WHITELIST=true
ONLINE_MODE=true
MAX_PLAYERS=50
```

### Discord-Integrated Server

```env
# Server settings
GAMEMODE=survival
MAX_PLAYERS=20

# Discord integration (DiscordSRV)
DISCORD_BOT_TOKEN=your-bot-token-here
DISCORD_CHAT_CHANNEL_ID=123456789012345678
DISCORD_CONSOLE_CHANNEL_ID=123456789012345679
DISCORD_ENABLE_PRESENCE=true
```

### Bedrock + Java Crossplay

```env
# Java server
GAMEMODE=survival
MAX_PLAYERS=30

# Geyser (Bedrock support)
GEYSER_PORT=19132
GEYSER_AUTH_TYPE=floodgate
GEYSER_MOTD1=Crossplay Server
GEYSER_MOTD2=Java + Bedrock Welcome!

# Floodgate
FLOODGATE_USERNAME_PREFIX=BE-
FLOODGATE_ENABLED=true
```

### Full-Featured Production Server

```env
# Core Server
GAMEMODE=survival
DIFFICULTY=hard
MAX_PLAYERS=100
VIEW_DISTANCE=12
ONLINE_MODE=true
WHITELIST_ENABLED=true
ENFORCE_WHITELIST=true

# RCON (for management tools)
ENABLE_RCON=true
RCON_PORT=25575
RCON_PASSWORD=secure-password-here

# Discord
DISCORD_BOT_TOKEN=your-token
DISCORD_CHAT_CHANNEL_ID=123456789
DISCORD_CONSOLE_CHANNEL_ID=987654321
DISCORD_ENABLE_PRESENCE=true
DISCORD_CHAT_CONSOLE_COMMANDS_ENABLED=true
DISCORD_CHAT_CONSOLE_ROLES=Admin,Moderator

# Bedrock Support
GEYSER_PORT=19132
GEYSER_AUTH_TYPE=floodgate
FLOODGATE_USERNAME_PREFIX=.

# BlueMap
BLUEMAP_WEBSERVER_ENABLED=true
BLUEMAP_PORT=8100
BLUEMAP_RENDER_THREADS=4
```

---

## Advanced Configuration

### Force Config Regeneration

Regenerate all configs even if environment hasn't changed:

```bash
docker-compose exec minecraft sh -c "MINECRAFT_FORCE_CONFIG_REGEN=true /entrypoint.sh"
```

Or in docker-compose.yml:

```yaml
environment:
  MINECRAFT_FORCE_CONFIG_REGEN: "true"
```

### Environment Snapshot

Configs are regenerated automatically when environment variables change. The snapshot is stored at:

```
/data/.env_snapshot
```

To view current snapshot:

```bash
docker-compose exec minecraft cat /data/.env_snapshot
```

### Loading Custom Defaults

You can mount your own defaults files:

```yaml
volumes:
  - ./my-custom-defaults.env:/defaults/custom.env
```

Then update `entrypoint.sh` to source it.

### Debugging Variables

See which defaults were loaded:

```bash
docker-compose logs minecraft | grep "Loading.*defaults"
```

Check if a variable is set:

```bash
docker-compose exec minecraft sh -c 'echo $DISCORD_BOT_TOKEN'
```

### Variable Naming Conventions

- `DISCORD_*` - DiscordSRV plugin settings
- `GEYSER_*` - Geyser plugin settings
- `FLOODGATE_*` - Floodgate plugin settings
- `BLUEMAP_*` - BlueMap plugin settings
- No prefix - Core Minecraft server settings

---

## Troubleshooting

### Variable Not Taking Effect

1. **Check load order**: Is the defaults file being loaded?
   ```bash
   docker-compose logs minecraft | grep "Loading"
   ```

2. **Check override**: Is a higher-priority value overriding it?
   ```bash
   docker-compose exec minecraft env | grep VAR_NAME
   ```

3. **Force regeneration**:
   ```bash
   docker-compose restart
   ```

### Plugin Settings Not Applied

1. **Check if template exists**:
   ```bash
   docker-compose exec minecraft ls /templates/plugins/
   ```

2. **Check if defaults loaded**:
   ```bash
   docker-compose logs minecraft | grep "plugin defaults"
   ```

3. **Verify plugin is installed**:
   ```bash
   docker-compose exec minecraft ls /data/plugins/
   ```

### Empty Values

Some variables intentionally default to empty (like `DISCORD_BOT_TOKEN`). These **must** be set by the user.

Check the defaults file to see what's intentionally empty:
```bash
docker-compose exec minecraft cat /defaults/discord.env | grep ":-}"
```

---

## Reference Links

- **Server Properties**: https://minecraft.fandom.com/wiki/Server.properties
- **DiscordSRV**: https://github.com/DiscordSRV/DiscordSRV/wiki
- **Geyser**: https://wiki.geysermc.org/geyser/
- **Floodgate**: https://wiki.geysermc.org/floodgate/
- **BlueMap**: https://bluemap.bluecolored.de/wiki/
- **Base Image**: https://github.com/itzg/docker-minecraft-server

---

**Last Updated**: December 1, 2025  
**Version**: 2.0 (Hybrid Defaults System)
