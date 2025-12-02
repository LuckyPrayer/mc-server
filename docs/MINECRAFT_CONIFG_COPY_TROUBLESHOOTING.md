# Minecraft Container Config Copy Troubleshooting

**Date:** December 1, 2025  
**Issue:** Template-generated configs in `/tmp/minecraft-configs/` are not being copied to `/data/plugins/`  
**Status:** ✅ RESOLVED - See [CONFIG_COPY_RESOLUTION.md](CONFIG_COPY_RESOLUTION.md)

---

## Resolution Summary

**Problem**: Post-init script using `CFG_SCRIPT_FILES` didn't execute at correct time.

**Solution**: Changed entrypoint to process templates directly to `/config` directory instead of `/tmp/minecraft-configs/`. The base image's built-in mechanism copies `/config` to `/data` before plugins initialize.

**Result**: ✅ Configs now reliably copied before plugins load. Smart regeneration and environment change detection working correctly.

**See**: [CONFIG_COPY_RESOLUTION.md](CONFIG_COPY_RESOLUTION.md) for complete details.

---

## Original Issue Documentation

Below is the original troubleshooting documentation for reference:

---

## Problem Summary

### What Works ✅
1. ✅ Environment variables are correctly passed to container
2. ✅ Template processing works perfectly (`envsubst`/`perl` substitution)
3. ✅ Generated configs in `/tmp/minecraft-configs/` have correct values
4. ✅ Environment snapshot tracking is implemented

### What Doesn't Work ❌
1. ❌ Generated configs are NOT copied from `/tmp/minecraft-configs/` to `/data/plugins/`
2. ❌ `CFG_SCRIPT_FILES` post-init script mechanism doesn't execute
3. ❌ Plugins create their own default configs instead of using our templates

---

## Evidence

### Generated Config is Correct
```bash
# Check the generated config in temp directory
$ docker exec minecraft-server cat /tmp/minecraft-configs/plugins/DiscordSRV/config.yml | grep -E 'BotToken|Channels|DiscordConsoleChannelId'

```

### But Actual Config Has Defaults
```bash
# Check the actual config being used
$ docker exec minecraft-server cat /data/plugins/DiscordSRV/config.yml | grep -E 'BotToken|Channels|DiscordConsoleChannelId'

```

### Copy Script Never Executes
```bash
# Search for copy messages in logs
$ docker logs minecraft-server 2>&1 | grep "Copying plugin configurations"

# No output - the script never ran!
```

---

## Root Cause Analysis

### Timeline of Events

1. **Container Starts** → Our `scripts/entrypoint.sh` runs
2. **Template Processing** → Configs generated in `/tmp/minecraft-configs/` ✅
3. **Post-Init Script Created** → `/tmp/post-init.sh` created with copy logic ✅
4. **CFG_SCRIPT_FILES Set** → `export CFG_SCRIPT_FILES="/tmp/post-init.sh"` ✅
5. **Base Image Starts** → `exec /start` from itzg/minecraft-server
6. **❌ Problem: Base image doesn't execute our post-init script**
7. **Base Image Config Copy** → Copies from `/config` and `/plugins` (wrong locations)
8. **Server Starts** → Plugins create default configs
9. **DiscordSRV Loads** → Generates own default config with placeholders

### Why CFG_SCRIPT_FILES Doesn't Work

The `CFG_SCRIPT_FILES` mechanism from itzg/minecraft-server:
- Is documented but may not work as expected in all scenarios
- Runs AFTER the base image's config copy phase
- May not execute before plugins initialize
- Timing issue: Plugins generate defaults before our script runs

### Why Manual Deletion Doesn't Help

When we delete the config and restart:
1. Config is deleted ✅
2. Container restarts and processes templates ✅
3. Our post-init script still doesn't run ❌
4. DiscordSRV plugin creates NEW default config ❌
5. We're back to placeholders

---

## Attempted Solutions

### ❌ Attempt 1: Using CFG_SCRIPT_FILES
```bash
# In scripts/entrypoint.sh
export CFG_SCRIPT_FILES="/tmp/post-init.sh"
exec /start
```
**Result:** Script created but never executed by base image

### ❌ Attempt 2: Delete Existing Config
```bash
docker exec minecraft-server rm /data/plugins/DiscordSRV/config.yml
docker restart minecraft-server
```
**Result:** Plugin regenerates default config instead of using our template

### ❌ Attempt 3: Using cp -rv to Overwrite
```bash
# In post-init script
cp -rv "$MINECRAFT_CONFIGS_TEMP/plugins/"* /data/plugins/
```
**Result:** Script never executes, so command never runs

---

## Working Solutions

### ✅ Solution 1: Copy Templates to /config Directory (RECOMMENDED)

Instead of using `/tmp/minecraft-configs/`, put templates where the base image expects them:

```bash
# In scripts/entrypoint.sh
# Change from:
TEMP_DIR="/tmp/minecraft-configs"

# To:
TEMP_DIR="/config"

# Process templates directly to /config
process_template "$template_file" "/config/plugins/${rel_path%.template}"

# The base image will copy from /config to /data automatically
```

**Advantages:**
- ✅ Works with existing base image mechanisms
- ✅ No need for post-init scripts
- ✅ Base image handles timing correctly
- ✅ Configs copied before plugins initialize

**Implementation:**
```bash
#!/bin/bash
# scripts/entrypoint.sh

# Process templates directly to /config
if [ -d "/templates" ]; then
    echo "Processing templates to /config directory..."
    
    # Process plugin templates
    if [ -d "/templates/plugins" ]; then
        echo "Processing plugin configuration templates..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/plugins/}"
            output_file="/config/plugins/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/plugins -name "*.template" -type f -print0)
    fi
    
    # Process server templates
    if [ -d "/templates/server" ]; then
        echo "Processing server configuration templates..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/server/}"
            output_file="/config/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/server -name "*.template" -type f -print0)
    fi
fi

# Let the base image handle copying /config -> /data
exec /start
```

---

### ✅ Solution 2: Use REPLACE_ENV Variables

Use the base image's built-in environment variable replacement:

```yaml
# docker-compose.yml
environment:
  # Prefix with CFG_ to trigger replacement in /config files
  - CFG_DISCORD_BOT_TOKEN=${MINECRAFT_DISCORD_BOT_TOKEN}
  - CFG_DISCORD_GUILD_ID=1353510916372692992
  - CFG_DISCORD_CHAT_CHANNEL_ID=1444872779307683982
  - CFG_DISCORD_CONSOLE_CHANNEL_ID=1444872739260207205
```

**Template format:**
```yaml
# In /config/plugins/DiscordSRV/config.yml
BotToken: "${CFG_DISCORD_BOT_TOKEN}"
Channels: {"global": "${CFG_DISCORD_CHAT_CHANNEL_ID}"}
DiscordConsoleChannelId: "${CFG_DISCORD_CONSOLE_CHANNEL_ID}"
```

**Advantages:**
- ✅ Uses base image's mc-image-helper for replacement
- ✅ Automatic sync and interpolation
- ✅ Works with base image timing

**Disadvantages:**
- ⚠️ Requires different variable names (CFG_ prefix)
- ⚠️ Less flexible than custom templates

---

### ✅ Solution 3: Manual Copy in Entrypoint (HACK)

Force copy before base image starts plugins:

```bash
#!/bin/bash
# scripts/entrypoint.sh

# Process templates to temp directory
TEMP_DIR="/tmp/minecraft-configs"
# ... template processing ...

# DON'T use post-init script
# Instead, copy NOW before starting base image

# Initialize /data if needed
if [ ! -d "/data" ]; then
    mkdir -p /data
fi

# Copy configs BEFORE base image starts
echo "Copying processed configurations to /data..."
if [ -d "$TEMP_DIR/plugins" ]; then
    mkdir -p /data/plugins
    
    # Force overwrite with -f flag
    cp -rfv "$TEMP_DIR/plugins/"* /data/plugins/
    echo "✓ Plugin configs copied"
fi

if [ -d "$TEMP_DIR/server" ]; then
    cp -rfv "$TEMP_DIR/server/"* /data/
    echo "✓ Server configs copied"
fi

# Now start base image
exec /start
```

**Advantages:**
- ✅ Guaranteed to run before plugins
- ✅ Simple and direct
- ✅ Force overwrites existing configs

**Disadvantages:**
- ⚠️ Copies before /data volume is fully mounted
- ⚠️ May cause permission issues
- ⚠️ Hacky solution

---

## Recommended Fix: Solution 1 with Smart Detection

Combine Solution 1 with environment snapshot for best results:

```bash
#!/bin/bash
# scripts/entrypoint.sh - FINAL RECOMMENDED VERSION

set -e

echo "======================================"
echo "Minecraft Server - Config Manager"
echo "======================================"
echo ""

# Environment snapshot for change detection
SNAPSHOT_FILE="/data/.env_snapshot"
SNAPSHOT_NEW="/tmp/.env_snapshot.new"

# Function to process templates
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    echo "  Processing: $(basename "$template_file")"
    mkdir -p "$(dirname "$output_file")"
    
    if command -v envsubst &> /dev/null; then
        envsubst < "$template_file" > "$output_file"
    else
        perl -pe 's/\$\{([^}]+)\}/$ENV{$1}/g' "$template_file" > "$output_file"
    fi
}

# Create new environment snapshot
create_env_snapshot() {
    # Extract all environment variables used in templates
    local vars=$(find /templates -name "*.template" -type f -exec grep -oh '\${[^}]*}' {} \; | \
                 sed 's/\${//g; s/}//g; s/:.*//g' | sort -u)
    
    echo "# Environment snapshot - $(date -Iseconds)" > "$SNAPSHOT_NEW"
    for var in $vars; do
        echo "${var}=${!var}" >> "$SNAPSHOT_NEW"
    done
}

# Check if configs need regeneration
needs_regeneration() {
    # Force regeneration flag
    if [ "${MINECRAFT_FORCE_CONFIG_REGEN:-false}" = "true" ]; then
        echo "Force regeneration enabled"
        return 0
    fi
    
    # No snapshot = first run
    if [ ! -f "$SNAPSHOT_FILE" ]; then
        echo "No environment snapshot found - first run"
        return 0
    fi
    
    # Compare snapshots
    create_env_snapshot
    if ! diff -q "$SNAPSHOT_FILE" "$SNAPSHOT_NEW" > /dev/null 2>&1; then
        echo "Environment variables changed:"
        diff "$SNAPSHOT_FILE" "$SNAPSHOT_NEW" || true
        return 0
    fi
    
    echo "Environment unchanged - skipping config regeneration"
    return 1
}

# Process templates if needed
if needs_regeneration; then
    echo ""
    echo "Regenerating configurations..."
    echo ""
    
    # Process templates directly to /config (base image will copy to /data)
    if [ -d "/templates/plugins" ]; then
        echo "Processing plugin templates..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/plugins/}"
            output_file="/config/plugins/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/plugins -name "*.template" -type f -print0)
    fi
    
    if [ -d "/templates/server" ]; then
        echo "Processing server templates..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/server/}"
            output_file="/config/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/server -name "*.template" -type f -print0)
    fi
    
    echo ""
    echo "✓ Configuration regeneration complete"
    echo ""
    
    # Save new snapshot (will be moved to /data by base image)
    mv "$SNAPSHOT_NEW" "/config/.env_snapshot"
else
    echo ""
    echo "✓ Using existing configurations"
    echo ""
fi

echo "======================================"
echo "Starting Minecraft Server..."
echo "======================================"
echo ""

# Start base image
exec /start
```

**Features:**
- ✅ Smart environment change detection
- ✅ Force regeneration flag support
- ✅ Works with base image's /config → /data copy
- ✅ Proper timing - configs ready before plugins load
- ✅ Clear feedback on what's happening

---

## Testing the Fix

### Test 1: Fresh Installation
```bash
# Remove volume and start fresh
docker-compose down -v
docker-compose up -d

# Wait for server to start
sleep 30

# Verify configs
docker exec minecraft-server cat /data/plugins/DiscordSRV/config.yml | grep DiscordConsoleChannelId
# Expected: "1444872739260207205"
```

### Test 2: Environment Change Detection
```bash
# Change a channel ID in docker-compose.yml
# Edit: DISCORD_CONSOLE_CHANNEL_ID=9999999999999999999

# Restart
docker-compose restart minecraft-server

# Check logs
docker logs minecraft-server 2>&1 | grep "Environment variables changed"
# Expected: Shows diff of changed variables

# Verify new value in config
docker exec minecraft-server grep DiscordConsoleChannelId /data/plugins/DiscordSRV/config.yml
# Expected: "9999999999999999999"
```

### Test 3: No Changes (Config Preserved)
```bash
# Restart without changes
docker-compose restart minecraft-server

# Check logs
docker logs minecraft-server 2>&1 | grep "Environment unchanged"
# Expected: "Environment unchanged - skipping config regeneration"

# Verify config still has correct values
docker exec minecraft-server grep DiscordConsoleChannelId /data/plugins/DiscordSRV/config.yml
```

### Test 4: Force Regeneration
```bash
# Add force flag
docker-compose down
# Edit docker-compose.yml: add MINECRAFT_FORCE_CONFIG_REGEN=true
docker-compose up -d

# Check logs
docker logs minecraft-server 2>&1 | grep "Force regeneration"
# Expected: "Force regeneration enabled"

# Configs should be regenerated
```

---

## Implementation Checklist

### In mc-server Repository

- [ ] **Update `scripts/entrypoint.sh`**
  - [ ] Change `TEMP_DIR` from `/tmp/minecraft-configs` to `/config`
  - [ ] Remove post-init script creation
  - [ ] Add environment snapshot logic
  - [ ] Add change detection with diff display
  - [ ] Process templates directly to `/config`

- [ ] **Update Templates**
  - [ ] Verify all templates use simple `${VAR}` syntax (no `:?` or `:-`)
  - [ ] Test each template with `envsubst`

- [ ] **Update Dockerfile**
  - [ ] Ensure `/config` directory exists
  - [ ] No changes needed for /templates

- [ ] **Testing**
  - [ ] Test fresh installation
  - [ ] Test environment change detection
  - [ ] Test unchanged environment (preserve configs)
  - [ ] Test force regeneration flag
  - [ ] Test with manual config edits (should preserve when env unchanged)

- [ ] **Documentation**
  - [ ] Update README with config regeneration behavior
  - [ ] Document `MINECRAFT_FORCE_CONFIG_REGEN` flag
  - [ ] Add troubleshooting section
  - [ ] Document environment snapshot location

### In Homelab Repository

- [ ] **Test Deployment**
  - [ ] Deploy to dev environment
  - [ ] Verify Discord integration works
  - [ ] Verify RCON works
  - [ ] Test config regeneration on env change

- [ ] **Update Documentation**
  - [ ] Document new config regeneration behavior
  - [ ] Update deployment guide
  - [ ] Add troubleshooting steps

---

## Current Workaround (Until Fixed)

Since the automatic copy doesn't work, manually copy the generated config:

```bash
# 1. Verify the generated config is correct
docker exec minecraft-server cat /tmp/minecraft-configs/plugins/DiscordSRV/config.yml | grep DiscordConsoleChannelId

# 2. Manually copy it
docker exec minecraft-server cp /tmp/minecraft-configs/plugins/DiscordSRV/config.yml /data/plugins/DiscordSRV/config.yml

# 3. Restart server to reload config
docker exec minecraft-server rcon-cli stop
# Server will auto-restart via compose

# 4. Verify it worked
docker exec minecraft-server cat /data/plugins/DiscordSRV/config.yml | grep DiscordConsoleChannelId
```

---

## Related Files

- `scripts/entrypoint.sh` - Main container entrypoint (NEEDS FIX)
- `templates/plugins/DiscordSRV/config.yml.template` - Discord config template
- `Dockerfile` - Container build instructions
- `playbooks/roles/homelab-compose/templates/docker-compose.yml.j2` - Deployment config

## References

- itzg/minecraft-server documentation: https://github.com/itzg/docker-minecraft-server
- CFG_SCRIPT_FILES mechanism: https://github.com/itzg/docker-minecraft-server#optional-plugins-mods-and-config-files
- Environment variable replacement: https://github.com/itzg/docker-minecraft-server#replacing-variables-inside-configs

---

## Status

**Current State:** ❌ Config generation works but copy mechanism fails  
**Root Cause:** Using CFG_SCRIPT_FILES post-init script which doesn't execute at correct time  
**Recommended Fix:** Solution 1 - Process templates directly to `/config` directory  
**Priority:** 🔴 HIGH - Blocks Discord integration functionality  
**Estimated Effort:** 1-2 hours to implement and test
