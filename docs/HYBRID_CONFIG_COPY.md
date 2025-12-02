# Hybrid Configuration Copy Strategy

**Date**: December 1, 2025  
**Status**: ✅ IMPLEMENTED  
**Approach**: Hybrid - Server configs via `/config`, Plugin configs via direct copy

---

## Overview

The entrypoint script uses a hybrid approach to ensure reliable configuration delivery:

1. **Server configs** → Processed to `/config` → Base image copies to `/data`
2. **Plugin configs** → Processed to `/tmp/minecraft-plugin-configs` → Direct copy to `/data/plugins` via post-init script

---

## Why Hybrid Approach?

### Problem with Pure /config Approach

While `/config` works well for server-level configs, plugin configs have timing issues:
- Base image copies `/config` → `/data` early in initialization
- Plugin folders may not exist yet
- Plugins may overwrite with defaults before our configs arrive

### Solution: Direct Plugin Config Copy

**Server Configs** (server.properties, bukkit.yml, etc.):
- ✅ Use `/config` → Base image handles timing correctly
- ✅ These files are needed before server starts
- ✅ Base image is designed for this

**Plugin Configs** (DiscordSRV, Geyser, etc.):
- ✅ Copy directly to `/data/plugins` via post-init script
- ✅ Happens after base image initializes `/data`
- ✅ Happens after plugin folders exist
- ✅ Before plugins actually load

---

## How It Works

### Phase 1: Template Processing (entrypoint.sh)

```bash
# Server templates → /config
/templates/server/server.properties.template
  → /config/server.properties

/templates/server/bukkit.yml.template
  → /config/bukkit.yml

# Plugin templates → /tmp/minecraft-plugin-configs
/templates/plugins/DiscordSRV/config.yml.template
  → /tmp/minecraft-plugin-configs/DiscordSRV/config.yml

/templates/plugins/Geyser-Spigot/config.yml.template
  → /tmp/minecraft-plugin-configs/Geyser-Spigot/config.yml
```

### Phase 2: Base Image Initialization

```bash
# Base image (/start) runs:
1. Copy /config → /data
   - server.properties → /data/server.properties
   - bukkit.yml → /data/bukkit.yml
   - .env_snapshot → /data/.env_snapshot

2. Create /data/plugins directory
3. Run CFG_SCRIPT_FILES scripts
```

### Phase 3: Plugin Config Copy (post-init script)

```bash
# /tmp/copy-plugin-configs.sh runs:
1. Wait for /data initialization (sleep 2)
2. Copy /tmp/minecraft-plugin-configs/* → /data/plugins/
   - DiscordSRV/config.yml → /data/plugins/DiscordSRV/config.yml
   - Geyser-Spigot/config.yml → /data/plugins/Geyser-Spigot/config.yml
3. Verify copy succeeded
4. List copied files
```

### Phase 4: Server Start

```bash
# Server starts with all configs in place:
- /data/server.properties ✅
- /data/bukkit.yml ✅
- /data/plugins/DiscordSRV/config.yml ✅
- /data/plugins/Geyser-Spigot/config.yml ✅
```

---

## Directory Structure

```
Container Filesystem:
├── /templates/                    # Built into image
│   ├── server/
│   │   ├── server.properties.template
│   │   ├── bukkit.yml.template
│   │   └── spigot.yml.template
│   └── plugins/
│       ├── DiscordSRV/
│       │   └── config.yml.template
│       └── Geyser-Spigot/
│           └── config.yml.template
│
├── /config/                       # Server configs (base image will copy)
│   ├── server.properties
│   ├── bukkit.yml
│   ├── spigot.yml
│   └── .env_snapshot
│
├── /tmp/minecraft-plugin-configs/ # Plugin configs (we copy directly)
│   ├── DiscordSRV/
│   │   └── config.yml
│   └── Geyser-Spigot/
│       └── config.yml
│
└── /data/                         # Final location (persistent volume)
    ├── server.properties          # From /config (base image)
    ├── bukkit.yml                 # From /config (base image)
    ├── spigot.yml                 # From /config (base image)
    ├── .env_snapshot              # From /config (base image)
    └── plugins/
        ├── DiscordSRV/
        │   └── config.yml         # From /tmp (our script)
        └── Geyser-Spigot/
            └── config.yml         # From /tmp (our script)
```

---

## Log Output

### Successful Run

```bash
======================================
Minecraft Server - Template Processor
======================================

Setting default values for environment variables...
✓ Default values set

Environment variables have changed since last run

Changes detected:
-DISCORD_BOT_TOKEN=old_value
+DISCORD_BOT_TOKEN=new_value

Processing templates...

Processing server configuration templates to /config...
  Processing: server.properties
  ✓ Generated successfully
  Processing: bukkit.yml
  ✓ Generated successfully
  → Server configs will be copied by base image to /data

Processing plugin configuration templates to /tmp/minecraft-plugin-configs...
  Processing: config.yml
  ✓ Generated successfully
  Processing: config.yml
  ✓ Generated successfully
  → Plugin configs will be copied directly to /data/plugins

Saving environment snapshot to /config/.env_snapshot
✓ Template processing complete!

======================================
Starting Minecraft Server...
======================================

Creating post-init script to copy plugin configs...
✓ Post-init script created

Base image will now:
  1. Copy server configs from /config to /data
  2. Initialize server files
  3. Run post-init script to copy plugin configs to /data/plugins
  4. Start Minecraft server

[Base image logs...]

======================================
Copying Plugin Configurations
======================================
Source: /tmp/minecraft-plugin-configs
Target: /data/plugins

Copying plugin configurations...
'/tmp/minecraft-plugin-configs/DiscordSRV/config.yml' -> '/data/plugins/DiscordSRV/config.yml'
'/tmp/minecraft-plugin-configs/Geyser-Spigot/config.yml' -> '/data/plugins/Geyser-Spigot/config.yml'

✓ Plugin configurations copied successfully!

Plugin configs in /data/plugins:
/data/plugins/DiscordSRV/config.yml
/data/plugins/Geyser-Spigot/config.yml
```

---

## Benefits

### Reliability ✅
- **Server configs**: Use proven base image mechanism
- **Plugin configs**: Direct copy ensures they're in place before plugins load
- **No timing issues**: Each type handled optimally

### Control ✅
- **Visibility**: Post-init script logs exactly what's copied
- **Verification**: Can see if copy succeeded
- **Debugging**: Easy to inspect `/tmp/minecraft-plugin-configs` before copy

### Flexibility ✅
- **Selective copying**: Could add logic to only copy certain plugins
- **Backup support**: Could backup existing configs before overwrite
- **Conditional logic**: Different behavior for different plugins

### Smart Regeneration Compatible ✅
- Environment snapshot in `/config/.env_snapshot`
- Only regenerates when environment changes
- Force flag still works: `MINECRAFT_FORCE_CONFIG_REGEN=true`

---

## Verification

### Check Server Configs
```bash
# Verify server configs copied by base image
docker exec minecraft-server ls -la /data/*.properties /data/*.yml
docker exec minecraft-server cat /data/server.properties | grep level-name
```

### Check Plugin Configs
```bash
# Verify plugin configs copied by our script
docker exec minecraft-server ls -la /data/plugins/*/config.yml
docker exec minecraft-server cat /data/plugins/DiscordSRV/config.yml | grep BotToken
```

### Check Copy Logs
```bash
# View plugin copy logs
docker logs minecraft-server 2>&1 | grep -A 20 "Copying Plugin Configurations"
```

### Check Environment Snapshot
```bash
# Verify snapshot was copied
docker exec minecraft-server cat /data/.env_snapshot | head -10
```

---

## Troubleshooting

### Plugin Configs Not Copied

**Symptom**: Plugins have default configs instead of template values

**Check**:
```bash
# 1. Was post-init script created?
docker logs minecraft-server | grep "Creating post-init script"

# 2. Did script run?
docker logs minecraft-server | grep "Copying Plugin Configurations"

# 3. Were configs generated?
docker exec minecraft-server ls -la /tmp/minecraft-plugin-configs/

# 4. Check for errors
docker logs minecraft-server | grep -i error
```

**Solution**:
```bash
# Force regeneration
MINECRAFT_FORCE_CONFIG_REGEN=true docker-compose restart minecraft-server
```

### Server Configs Not Copied

**Symptom**: Server properties have defaults

**Check**:
```bash
# 1. Were templates processed?
docker logs minecraft-server | grep "Processing server configuration"

# 2. Are configs in /config?
docker exec minecraft-server ls -la /config/

# 3. Base image copy logs
docker logs minecraft-server | grep -i "config"
```

### Post-Init Script Not Running

**Symptom**: No "Copying Plugin Configurations" in logs

**Check**:
```bash
# 1. Was script created?
docker exec minecraft-server ls -la /tmp/copy-plugin-configs.sh

# 2. Is it executable?
docker exec minecraft-server cat /tmp/copy-plugin-configs.sh

# 3. Is CFG_SCRIPT_FILES set?
docker exec minecraft-server printenv | grep CFG_SCRIPT_FILES
```

---

## Migration from Previous Approach

### If Coming from Pure /config Approach

No changes needed in docker-compose.yml or environment variables. Just rebuild and redeploy:

```bash
# Rebuild image with new entrypoint
./build.sh dev

# Redeploy
docker-compose up -d

# Verify
docker logs minecraft-server | grep "Copying Plugin Configurations"
```

### If Coming from Manual Copy Workaround

Can remove any manual copy scripts or workarounds:

```bash
# Remove old workarounds
rm -f scripts/manual-copy-configs.sh

# Use new built-in mechanism
docker-compose up -d
```

---

## Performance

### Overhead
- **Template processing**: Same as before (~1-2 seconds)
- **Post-init script**: ~2-3 seconds (includes sleep)
- **Total delay**: ~3-5 seconds (acceptable for container start)

### Optimization
- Only copies when `SHOULD_PROCESS=true`
- Skips if no environment changes
- Minimal I/O operations

---

## Future Enhancements

Potential improvements:

1. **Parallel copying**: Copy server and plugin configs simultaneously
2. **Backup before overwrite**: Save existing configs before replacing
3. **Selective plugin copy**: Only copy configs for installed plugins
4. **Diff display**: Show what changed in plugin configs
5. **Retry logic**: Retry copy if it fails initially

---

## Related Documentation

- [CONFIG_COPY_RESOLUTION.md](CONFIG_COPY_RESOLUTION.md) - Previous resolution attempt
- [CONFIG_REGENERATION.md](CONFIG_REGENERATION.md) - Smart regeneration feature
- [TEMPLATING_GUIDE.md](TEMPLATING_GUIDE.md) - Template syntax and usage

---

**Status**: ✅ IMPLEMENTED  
**Tested**: December 1, 2025  
**Version**: 2.0 (Hybrid approach)  
**Recommended**: Yes
