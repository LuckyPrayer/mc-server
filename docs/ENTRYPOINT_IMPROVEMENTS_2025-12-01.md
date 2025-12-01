# Entrypoint Script Improvements - Smart Configuration Regeneration

**Date**: December 1, 2025  
**Feature**: Smart detection and force flag for configuration regeneration

---

## Summary

Enhanced the `scripts/entrypoint.sh` to intelligently manage configuration file regeneration with two key features:

### 1. Smart Detection (Automatic)

**What it does**: Tracks environment variable values and only regenerates configurations when they actually change.

**How it works**:
- Creates a snapshot of relevant environment variables in `/data/.env_snapshot`
- On each container start, compares current environment with saved snapshot
- Only processes templates if changes are detected
- Automatically saves new snapshot after successful configuration copy

**Benefits**:
- ✅ Faster container restarts (skips unnecessary template processing)
- ✅ Preserves manual config edits when environment unchanged
- ✅ Transparent - shows what changed in logs
- ✅ Automatic - no user intervention needed

**Tracked Variables**:
- `DISCORD_*` - All Discord configuration
- `GEYSER_*` - Geyser/Bedrock bridge settings
- `FLOODGATE_*` - Floodgate authentication
- `BLUEMAP_*` - BlueMap configuration
- `MINECRAFT_*` - Minecraft-specific settings
- `SERVER_*`, `LEVEL_*`, `RCON_*` - Server properties
- `GAMEMODE`, `DIFFICULTY`, `PVP`, etc. - Common settings

### 2. Force Flag (Manual Override)

**What it does**: Allows manual regeneration of all configuration files regardless of whether environment changed.

**Usage**:
```bash
MINECRAFT_FORCE_CONFIG_REGEN=true
```

**Use cases**:
- Template files were updated in image
- Need to revert manual config changes
- Debugging template processing
- Config corruption recovery

---

## Implementation Details

### Files Modified

**scripts/entrypoint.sh**:
- Added `ENV_SNAPSHOT_FILE` and `TEMP_DIR` configuration constants
- Added `get_env_snapshot()` function to capture relevant environment variables
- Added `needs_regeneration()` function to check if processing needed
- Added `save_env_snapshot()` function to persist environment state
- Modified template processing to be conditional based on `needs_regeneration()`
- Modified post-init script to save snapshot after successful config copy

### Key Functions

```bash
# Get snapshot of current environment variables
get_env_snapshot()
  -> Returns sorted list of relevant environment variables

# Check if configs need regeneration
needs_regeneration()
  -> Returns 0 (true) if regeneration needed
  -> Returns 1 (false) if configs should be preserved
  -> Checks:
     1. MINECRAFT_FORCE_CONFIG_REGEN flag
     2. Existence of /data/.env_snapshot
     3. Difference between current and saved snapshot

# Save environment snapshot
save_env_snapshot()
  -> Writes current environment to /data/.env_snapshot
```

### Workflow Changes

**Before**:
```
Container Start
  ↓
Set Defaults
  ↓
Process ALL Templates (every time)
  ↓
Copy ALL Configs to /data (overwrites)
  ↓
Start Server
```

**After**:
```
Container Start
  ↓
Set Defaults
  ↓
Check needs_regeneration()
  ├─ Force flag set? → Process Templates
  ├─ No snapshot? → Process Templates
  ├─ Environment changed? → Process Templates
  └─ No changes? → Skip Processing
  ↓
[If processed] Copy Configs to /data
[If processed] Save Environment Snapshot
  ↓
Start Server
```

---

## Log Output Examples

### First Run (No Snapshot)
```
======================================
Minecraft Server - Template Processor
======================================

Setting default values for environment variables...
✓ Default values set

No environment snapshot found - first run or /data was cleared
Processing templates...

Processing server configuration templates...
Processing: server.properties.template -> /tmp/minecraft-configs/server/server.properties
  ✓ Generated successfully
...
✓ Template processing complete!

======================================
Starting Minecraft Server...
======================================
```

### Normal Restart (No Changes)
```
======================================
Minecraft Server - Template Processor
======================================

Setting default values for environment variables...
✓ Default values set

No environment changes detected - skipping template processing
✓ Using existing configurations

======================================
Starting Minecraft Server...
======================================

======================================
Skipping configuration copy
======================================
Using existing configurations from /data
```

### Environment Changed
```
======================================
Minecraft Server - Template Processor
======================================

Setting default values for environment variables...
✓ Default values set

Environment variables have changed since last run

Changes detected:
-DISCORD_BOT_TOKEN=old_value
+DISCORD_BOT_TOKEN=new_value
-DISCORD_CHAT_CHANNEL_ID=123456
+DISCORD_CHAT_CHANNEL_ID=789012

Processing templates...
...
✓ Template processing complete!

======================================
Copying processed configurations...
======================================
...
✓ Configuration copy complete!
✓ Environment snapshot saved
```

### Force Regeneration
```
======================================
Minecraft Server - Template Processor
======================================

Setting default values for environment variables...
✓ Default values set

Force regeneration flag detected (MINECRAFT_FORCE_CONFIG_REGEN=true)
Processing templates...
...
✓ Template processing complete!
```

---

## Testing

### Test Case 1: First Run
```bash
# Remove data volume to simulate first run
docker volume rm minecraft_data_dev

# Start container
docker-compose -f docker-compose.dev.yml up -d

# Verify snapshot created
docker exec minecraft-server ls -la /data/.env_snapshot

# Check logs
docker logs minecraft-server | grep "environment snapshot"
```

**Expected**: Templates processed, snapshot created

### Test Case 2: Normal Restart (No Changes)
```bash
# Restart without changing environment
docker-compose -f docker-compose.dev.yml restart

# Check logs
docker logs minecraft-server | grep "No environment changes"
```

**Expected**: Templates skipped, existing configs used

### Test Case 3: Environment Variable Change
```bash
# Edit docker-compose.dev.yml to change DISCORD_BOT_TOKEN
nano docker-compose.dev.yml

# Restart
docker-compose -f docker-compose.dev.yml up -d

# Check logs
docker logs minecraft-server | grep "Changes detected"
```

**Expected**: Templates processed, diff shown in logs

### Test Case 4: Force Regeneration
```bash
# Add force flag temporarily
export MINECRAFT_FORCE_CONFIG_REGEN=true
docker-compose -f docker-compose.dev.yml restart
unset MINECRAFT_FORCE_CONFIG_REGEN

# Check logs
docker logs minecraft-server | grep "Force regeneration"
```

**Expected**: Templates processed, force flag detected

---

## Documentation Created

1. **docs/CONFIG_REGENERATION.md** - Complete guide for users
   - How it works
   - When to use force flag
   - Troubleshooting
   - Best practices

2. **README.md** - Updated with:
   - New features in feature list
   - Smart regeneration section
   - Link to CONFIG_REGENERATION.md

---

## Benefits

### For Users
- ✅ **Faster restarts**: Skip processing when nothing changed
- ✅ **Safer**: Preserves manual edits when appropriate
- ✅ **Transparent**: See what changed and why configs regenerated
- ✅ **Flexible**: Force regeneration when needed

### For Operations
- ✅ **Predictable**: Clear rules for when regeneration happens
- ✅ **Debuggable**: Logs show decision-making process
- ✅ **Recoverable**: Force flag allows fixing config issues
- ✅ **Efficient**: Reduces unnecessary I/O and processing

### For Development
- ✅ **Testable**: Can verify regeneration logic
- ✅ **Maintainable**: Clear separation of concerns
- ✅ **Extensible**: Easy to add more tracked variables
- ✅ **Observable**: Snapshot file provides audit trail

---

## Future Enhancements

Potential improvements for future versions:

1. **Per-Plugin Snapshots**: Track each plugin's variables separately
2. **Incremental Updates**: Only regenerate changed configs, not all
3. **Backup Before Regen**: Save current configs before overwriting
4. **Notification**: Webhook or log message when configs regenerated
5. **Dry-Run Mode**: Show what would be regenerated without doing it
6. **Snapshot History**: Keep last N snapshots for rollback

---

## Related Issues

This enhancement addresses:

1. **Discord Bot Token Issue** ([MINECRAFT_DISCORD_BOT_TOKEN_FIX.md](MINECRAFT_DISCORD_BOT_TOKEN_FIX.md))
   - Now properly detects when DISCORD_BOT_TOKEN changes
   - Regenerates DiscordSRV config automatically

2. **Template Processing Performance**
   - Reduces unnecessary processing on every restart
   - Makes containers start faster when no changes

3. **Manual Configuration Management**
   - Provides clear path for manual overrides (force flag)
   - Preserves manual edits when environment unchanged

---

**Status**: Implemented and documented  
**Version**: 1.0.0  
**Tested**: ✅ Development environment  
**Ready for Production**: ✅ Yes
