# Configuration Regeneration Guide

**Date**: December 1, 2025  
**Feature**: Smart configuration regeneration with environment variable tracking

---

## Overview

The Minecraft server container includes intelligent configuration management that automatically detects when environment variables change and regenerates configuration files only when needed.

---

## How It Works

### Smart Detection (Automatic)

The entrypoint script tracks environment variables used in configuration templates and automatically regenerates configs when changes are detected.

**Environment Snapshot**: On each successful container start, the script creates a snapshot of all relevant environment variables in `/data/.env_snapshot`.

**Tracked Variables**:
- `DISCORD_*` - DiscordSRV configuration
- `GEYSER_*` - Geyser configuration
- `FLOODGATE_*` - Floodgate configuration
- `BLUEMAP_*` - BlueMap configuration
- `MINECRAFT_*` - Minecraft-specific settings
- `SERVER_*` - Server properties
- And other common server variables (LEVEL_*, RCON_*, GAMEMODE, etc.)

**Regeneration Triggers**:
1. **First Run**: No snapshot exists (fresh container or cleared `/data`)
2. **Environment Change**: Any tracked variable has a different value
3. **Force Flag**: Manual override requested (see below)

**Benefits**:
- ✅ Automatic - no manual intervention needed
- ✅ Efficient - only regenerates when necessary
- ✅ Safe - preserves configs when nothing changed
- ✅ Transparent - logs show what changed

### Example Output

```bash
====================================== 
Minecraft Server - Template Processor
======================================

Setting default values for environment variables...
✓ Default values set

Environment variables have changed since last run

Changes detected:
-DISCORD_BOT_TOKEN=old_token_value
+DISCORD_BOT_TOKEN=new_token_value
-DISCORD_CHAT_CHANNEL_ID=123456789
+DISCORD_CHAT_CHANNEL_ID=987654321

Processing templates...

Processing server configuration templates...
  ✓ Generated successfully
...
✓ Template processing complete!
```

---

## Force Flag (Manual Override)

You can force regeneration of all configuration files regardless of whether environment variables changed.

### Usage

Set the environment variable:

```bash
MINECRAFT_FORCE_CONFIG_REGEN=true
```

### When to Use Force Regeneration

1. **Template Updates**: You've updated template files in the image
2. **Manual Changes**: You manually edited configs and want to revert to templates
3. **Debugging**: Testing template processing
4. **Recovery**: Config files are corrupted or missing

### Docker Compose Example

**One-time force regeneration**:

```bash
# Set environment variable and restart
MINECRAFT_FORCE_CONFIG_REGEN=true docker compose restart minecraft-server

# Or in docker-compose.yml temporarily:
services:
  minecraft-server:
    environment:
      - MINECRAFT_FORCE_CONFIG_REGEN=true
```

**Note**: Remove the flag after the container starts to prevent regenerating on every restart.

### Docker Run Example

```bash
docker run -d \
  --name minecraft-server \
  -e MINECRAFT_FORCE_CONFIG_REGEN=true \
  -e DISCORD_BOT_TOKEN=your_token \
  -v minecraft_data:/data \
  harbor.local/minecraft/server:latest
```

---

## Configuration File Locations

### Templates (in container image)
- `/templates/server/*.template` - Server configuration templates
- `/templates/plugins/*/` *.template` - Plugin configuration templates

### Generated Files (temporary)
- `/tmp/minecraft-configs/server/` - Processed server configs
- `/tmp/minecraft-configs/plugins/` - Processed plugin configs

### Final Location (persistent)
- `/data/` - Server properties, bukkit.yml, spigot.yml, paper configs
- `/data/plugins/` - Plugin configurations
- `/data/.env_snapshot` - Environment variable snapshot for change detection

---

## Workflow

### Normal Container Start

1. Container starts with environment variables
2. Script sets default values for unset variables
3. Script loads previous environment snapshot from `/data/.env_snapshot`
4. Script compares current environment with saved snapshot
5. **If no changes**: Skip template processing, use existing configs
6. **If changes detected**: Process templates and copy to `/data`
7. Save new environment snapshot
8. Start Minecraft server

### First Run / Fresh Data Volume

1. Container starts with environment variables
2. Script sets default values for unset variables
3. No snapshot found in `/data/.env_snapshot`
4. Process all templates
5. Copy configs to `/data`
6. Save environment snapshot
7. Start Minecraft server

### Force Regeneration

1. Container starts with `MINECRAFT_FORCE_CONFIG_REGEN=true`
2. Script sets default values for unset variables
3. Script detects force flag, skips environment comparison
4. Process all templates (overwrites existing)
5. Copy configs to `/data`
6. Save new environment snapshot
7. Start Minecraft server

---

## Troubleshooting

### Configs Not Regenerating

**Symptom**: Changed environment variable but config files didn't update

**Causes**:
1. Variable not in tracked list
2. Typo in variable name
3. Container not fully restarted

**Solution**:
```bash
# Check if variable is set correctly
docker exec minecraft-server printenv | grep YOUR_VARIABLE

# Force regeneration
docker compose stop minecraft-server
MINECRAFT_FORCE_CONFIG_REGEN=true docker compose up -d minecraft-server

# Check logs
docker logs minecraft-server 2>&1 | grep -A 20 "Template Processor"
```

### Configs Regenerating Every Time

**Symptom**: Templates process on every container restart even without changes

**Causes**:
1. `/data/.env_snapshot` file is being deleted
2. Volume permissions issue
3. Force flag left enabled

**Solution**:
```bash
# Check if snapshot file exists and is writable
docker exec minecraft-server ls -la /data/.env_snapshot

# Ensure force flag is not set
docker exec minecraft-server printenv | grep MINECRAFT_FORCE_CONFIG_REGEN

# Check volume mount
docker inspect minecraft-server | grep -A 5 Mounts
```

### Manual Config Changes Keep Getting Overwritten

**Symptom**: You edit a config file manually but it gets reset on restart

**Cause**: Config file is generated from template, and template is regenerating

**Solutions**:

**Option 1**: Edit the template (recommended for permanent changes)
```bash
# Update the template in your build
vim templates/plugins/DiscordSRV/config.yml.template

# Rebuild and redeploy image
./build.sh dev
./push-to-harbor.sh dev
```

**Option 2**: Prevent regeneration
```bash
# Make sure environment variables don't change between restarts
# The config will only be generated once and then preserved
```

**Option 3**: Remove from template system
```bash
# If you want to manage a config manually, remove its template
# The file will be preserved in /data after initial generation
```

---

## Best Practices

### 1. Use Environment Variables for Dynamic Values

Store secrets and environment-specific values in environment variables:

```yaml
environment:
  - DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN}
  - DISCORD_CHAT_CHANNEL_ID=${DISCORD_CHAT_CHANNEL_ID}
  - LEVEL_NAME=my-world
  - DIFFICULTY=normal
```

### 2. Use Templates for Static Configuration

Store server settings that change between environments in templates:

```yaml
# In template: server.properties.template
level-name=${LEVEL_NAME}
difficulty=${DIFFICULTY}
max-players=${MAX_PLAYERS}
```

### 3. Keep Force Flag Temporary

Only use `MINECRAFT_FORCE_CONFIG_REGEN=true` when needed, then remove it:

```bash
# DON'T do this:
environment:
  - MINECRAFT_FORCE_CONFIG_REGEN=true  # This will regenerate every time!

# DO this instead:
docker compose restart -e MINECRAFT_FORCE_CONFIG_REGEN=true minecraft-server
# Then remove the variable for next restart
```

### 4. Test Template Changes in Development

Before deploying template changes to production:

```bash
# Build dev image
./build.sh dev

# Test in dev environment
docker compose -f docker-compose.dev.yml up -d

# Verify configs
docker exec minecraft-server cat /data/plugins/DiscordSRV/config.yml

# If good, build and push production
./build.sh prod
./push-to-harbor.sh prod
```

### 5. Version Your Environment Snapshots

The `.env_snapshot` file in `/data` can be useful for troubleshooting:

```bash
# Backup before major changes
docker cp minecraft-server:/data/.env_snapshot ./env_snapshot.backup

# Compare snapshots
diff env_snapshot.backup <(docker exec minecraft-server cat /data/.env_snapshot)
```

---

## Related Documentation

- [MINECRAFT_DISCORD_BOT_TOKEN_FIX.md](MINECRAFT_DISCORD_BOT_TOKEN_FIX.md) - Discord bot token configuration fix
- [TEMPLATING_GUIDE.md](TEMPLATING_GUIDE.md) - Template syntax and usage
- [TEMPLATES_QUICKREF.md](TEMPLATES_QUICKREF.md) - Quick reference for available template variables

---

**Status**: Implemented and tested  
**Version**: 1.0.0  
**Last Updated**: December 1, 2025
