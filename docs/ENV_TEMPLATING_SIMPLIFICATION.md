# Environment Variable Templating Simplification

**Date**: December 1, 2025  
**Status**: 🔄 PROPOSAL FOR REVIEW

---

## Current State Analysis

### The Problem

**Complexity**: 
- 522 unique variables used across templates
- 98 variables have default values in entrypoint.sh
- 424 variables have NO defaults (will be empty if not set)
- entrypoint.sh is 334 lines, with ~100 lines just for defaults

**Maintainability Issues**:
- Hard to know which variables are required vs optional
- Easy to miss setting a variable
- Difficult to add new template variables
- No clear documentation of what each variable does
- Defaults are scattered and hard to find

**Performance**:
- 98 environment variable exports on every container start
- Many variables may never be used (e.g., BlueMap if not installed)

---

## Proposed Simplification Strategy

### Option 1: Consolidated Defaults File (RECOMMENDED)

Create a separate defaults configuration file that's easier to maintain.

**Structure**:
```bash
# defaults/env-defaults.conf
# Loaded by entrypoint.sh before processing templates

# Core Server Settings (Required)
GAMEMODE=${GAMEMODE:-survival}
DIFFICULTY=${DIFFICULTY:-normal}
MAX_PLAYERS=${MAX_PLAYERS:-20}
VIEW_DISTANCE=${VIEW_DISTANCE:-10}

# Whitelist (Optional - disabled by default)
WHITELIST_ENABLED=${WHITELIST_ENABLED:-false}
ENFORCE_WHITELIST=${ENFORCE_WHITELIST:-false}

# Discord Integration (Optional - only if DiscordSRV installed)
DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN:-}
DISCORD_CHAT_CHANNEL_ID=${DISCORD_CHAT_CHANNEL_ID:-}
# ... grouped by feature
```

**Benefits**:
- ✅ Separate concerns: entrypoint logic vs configuration
- ✅ Easier to find and update defaults
- ✅ Can be documented inline with comments
- ✅ Can be organized by feature/plugin
- ✅ Easier to version control
- ✅ Clear separation of required vs optional variables

**Implementation**:
```bash
# In entrypoint.sh, replace 98 export lines with:
if [ -f "/defaults/env-defaults.conf" ]; then
    echo "Loading default environment variables..."
    source /defaults/env-defaults.conf
fi
```

---

### Option 2: Smart Defaults with Categories

Keep defaults in entrypoint.sh but organize better:

```bash
# === CORE SERVER SETTINGS (Always needed) ===
export GAMEMODE="${GAMEMODE:-survival}"
export DIFFICULTY="${DIFFICULTY:-normal}"

# === DISCORD INTEGRATION (Only if DiscordSRV installed) ===
if [ -d "/templates/plugins/DiscordSRV" ]; then
    export DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"
    export DISCORD_CHAT_CHANNEL_ID="${DISCORD_CHAT_CHANNEL_ID:-}"
    # ... other Discord vars
fi

# === GEYSER/BEDROCK (Only if Geyser installed) ===
if [ -d "/templates/plugins/Geyser-Spigot" ]; then
    export GEYSER_PORT="${GEYSER_PORT:-19132}"
    # ... other Geyser vars
fi
```

**Benefits**:
- ✅ Only load defaults for installed plugins
- ✅ Faster startup (fewer exports)
- ✅ Clear organization
- ✅ Self-documenting

**Drawbacks**:
- ⚠️ Still clutters entrypoint.sh
- ⚠️ Harder to maintain inline

---

### Option 3: Dynamic Defaults from Template Analysis

Automatically detect which variables are used and provide defaults:

```bash
# Auto-detect variables from templates
extract_template_vars() {
    find /templates -name "*.template" -exec grep -oh '\${[^}]*}' {} \; | \
    sed 's/\${//g; s/}//g' | sort -u
}

# Apply common defaults programmatically
apply_smart_defaults() {
    # Boolean defaults
    for var in $(extract_template_vars | grep -E "ENABLE|ENABLED"); do
        export $var="${!var:-false}"
    done
    
    # Port defaults (common ranges)
    export RCON_PORT="${RCON_PORT:-25575}"
    export GEYSER_PORT="${GEYSER_PORT:-19132}"
    
    # etc.
}
```

**Benefits**:
- ✅ No manual maintenance of defaults
- ✅ Automatically handles new variables
- ✅ DRY principle

**Drawbacks**:
- ⚠️ Less explicit
- ⚠️ Harder to debug
- ⚠️ Magic behavior

---

### Option 4: Minimal Defaults + Documentation

Only set defaults for **critical** variables, document the rest:

**Critical Variables** (10-20):
```bash
# Only set defaults for variables that MUST have a value
export GAMEMODE="${GAMEMODE:-survival}"
export DIFFICULTY="${DIFFICULTY:-normal}"
export MAX_PLAYERS="${MAX_PLAYERS:-20}"
export WHITELIST_ENABLED="${WHITELIST_ENABLED:-false}"
export ENFORCE_WHITELIST="${ENFORCE_WHITELIST:-false}"
```

**Everything Else**: Document in `.env.example` and let users set explicitly

**Benefits**:
- ✅ Simplest entrypoint
- ✅ Forces explicit configuration
- ✅ Users know what they're setting

**Drawbacks**:
- ⚠️ More setup required
- ⚠️ Templates may have empty values
- ⚠️ Less "magic"

---

## Recommended Approach: Hybrid

Combine Option 1 (Consolidated File) + Option 4 (Minimal Critical Defaults)

### Structure

```
mc-server/
├── scripts/
│   └── entrypoint.sh           # Minimal, clean logic
├── defaults/
│   ├── core.env                # 10-20 critical defaults
│   ├── discord.env             # Discord plugin defaults (optional)
│   ├── geyser.env              # Geyser plugin defaults (optional)
│   └── advanced.env            # Advanced server tuning (optional)
└── docs/
    └── ENVIRONMENT_VARIABLES.md # Complete reference
```

### entrypoint.sh (Simplified)

```bash
#!/bin/bash
set -e

echo "======================================"
echo "Minecraft Server - Template Processor"
echo "======================================"

# Load critical defaults
load_defaults() {
    # Always load core defaults
    [ -f "/defaults/core.env" ] && source "/defaults/core.env"
    
    # Load plugin defaults only if plugin templates exist
    [ -d "/templates/plugins/DiscordSRV" ] && [ -f "/defaults/discord.env" ] && source "/defaults/discord.env"
    [ -d "/templates/plugins/Geyser-Spigot" ] && [ -f "/defaults/geyser.env" ] && source "/defaults/geyser.env"
    
    # Load advanced if requested
    [ "${LOAD_ADVANCED_DEFAULTS:-false}" = "true" ] && [ -f "/defaults/advanced.env" ] && source "/defaults/advanced.env"
}

echo "Loading default environment variables..."
load_defaults
echo "✓ Default values set"

# Rest of entrypoint logic...
```

### defaults/core.env

```bash
# Core Server Defaults
# Only essential variables that every server needs

# Game Settings
export GAMEMODE="${GAMEMODE:-survival}"
export DIFFICULTY="${DIFFICULTY:-normal}"
export PVP="${PVP:-true}"
export HARDCORE="${HARDCORE:-false}"

# Server Capacity
export MAX_PLAYERS="${MAX_PLAYERS:-20}"
export VIEW_DISTANCE="${VIEW_DISTANCE:-10}"
export SIMULATION_DISTANCE="${SIMULATION_DISTANCE:-10}"

# Access Control
export ONLINE_MODE="${ONLINE_MODE:-true}"
export WHITELIST_ENABLED="${WHITELIST_ENABLED:-false}"
export ENFORCE_WHITELIST="${ENFORCE_WHITELIST:-false}"

# World Settings
export LEVEL_NAME="${LEVEL_NAME:-world}"
export LEVEL_TYPE="${LEVEL_TYPE:-minecraft:normal}"
export SPAWN_MONSTERS="${SPAWN_MONSTERS:-true}"
export SPAWN_ANIMALS="${SPAWN_ANIMALS:-true}"

# RCON (Essential for management)
export ENABLE_RCON="${ENABLE_RCON:-true}"
export RCON_PORT="${RCON_PORT:-25575}"
```

### defaults/discord.env

```bash
# DiscordSRV Plugin Defaults
# Only loaded if /templates/plugins/DiscordSRV exists

# Core Discord Settings (Required if using plugin)
export DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"
export DISCORD_CHAT_CHANNEL_ID="${DISCORD_CHAT_CHANNEL_ID:-}"
export DISCORD_CONSOLE_CHANNEL_ID="${DISCORD_CONSOLE_CHANNEL_ID:-}"

# Optional Discord Features
export DISCORD_GAME_STATUS="${DISCORD_GAME_STATUS:-Minecraft}"
export DISCORD_ONLINE_STATUS="${DISCORD_ONLINE_STATUS:-ONLINE}"
export DISCORD_ENABLE_PRESENCE="${DISCORD_ENABLE_PRESENCE:-false}"

# Advanced Discord Settings
export DISCORD_FORCE_TLS="${DISCORD_FORCE_TLS:-true}"
export DISCORD_WEBHOOK_DELIVERY="${DISCORD_WEBHOOK_DELIVERY:-false}"
# ... etc
```

---

## Migration Plan

### Phase 1: Create Defaults Files (No Breaking Changes)

1. Create `defaults/` directory
2. Move existing defaults to appropriate files
3. Update entrypoint.sh to source defaults files
4. Test that everything still works
5. Document the new structure

**Status**: Can be done incrementally, no downtime needed

### Phase 2: Simplify Templates (Optional)

1. Review 522 template variables
2. Identify which are actually used
3. Remove unused variables from templates
4. Update documentation

**Status**: Can be done gradually, template by template

### Phase 3: Documentation Update

1. Create `ENVIRONMENT_VARIABLES.md` with:
   - Complete list of all variables
   - Which are required vs optional
   - Grouped by feature/plugin
   - Examples for common scenarios
2. Update existing docs to reference new structure

**Status**: Improves user experience, not technically required

---

## Benefits of Recommended Approach

### For Developers
- ✅ **Clean code**: Entrypoint logic separated from configuration
- ✅ **Easy to maintain**: Update one file per feature
- ✅ **Clear organization**: Find variables by category
- ✅ **Conditional loading**: Only load what's needed

### For Users
- ✅ **Better documentation**: Know what each variable does
- ✅ **Easier setup**: Copy relevant .env file sections
- ✅ **Less confusion**: Clear which variables are required
- ✅ **Faster startup**: Fewer unnecessary exports

### For Operations
- ✅ **Debugging**: Easy to see which defaults are active
- ✅ **Customization**: Override specific categories
- ✅ **Version control**: Track changes to defaults separately
- ✅ **Testing**: Test different default profiles

---

## Example: Before & After

### Before (Current)

**entrypoint.sh** (98 export lines):
```bash
export DISCORD_CONSOLE_CHANNEL_ID="${DISCORD_CONSOLE_CHANNEL_ID:-}"
export DISCORD_JDBC_URL="${DISCORD_JDBC_URL:-jdbc:mysql://HOST:PORT/DATABASE}"
export DISCORD_JDBC_PREFIX="${DISCORD_JDBC_PREFIX:-discordsrv}"
# ... 95 more lines
export GEYSER_PORT="${GEYSER_PORT:-19132}"
export GEYSER_MOTD1="${GEYSER_MOTD1:-Geyser}"
# ... many more
```

**Result**: 334 line file, hard to navigate

### After (Proposed)

**entrypoint.sh** (simplified):
```bash
echo "Loading default environment variables..."
[ -f "/defaults/core.env" ] && source "/defaults/core.env"
[ -d "/templates/plugins/DiscordSRV" ] && source "/defaults/discord.env" 2>/dev/null || true
[ -d "/templates/plugins/Geyser-Spigot" ] && source "/defaults/geyser.env" 2>/dev/null || true
echo "✓ Default values set"
```

**Result**: 4 lines instead of 98, much cleaner

**defaults/discord.env**:
```bash
# DiscordSRV Configuration Defaults
# Documentation: https://github.com/DiscordSRV/DiscordSRV/wiki

# === REQUIRED if using DiscordSRV ===
export DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"
export DISCORD_CHAT_CHANNEL_ID="${DISCORD_CHAT_CHANNEL_ID:-}"

# === OPTIONAL Features ===
export DISCORD_GAME_STATUS="${DISCORD_GAME_STATUS:-Minecraft}"
# ... well organized and documented
```

**Result**: Self-documenting, organized, easy to find

---

## Implementation Checklist

### Phase 1: Foundation (1-2 hours)
- [ ] Create `defaults/` directory structure
- [ ] Create `defaults/core.env` with 15-20 critical variables
- [ ] Create `defaults/discord.env` with Discord-specific variables
- [ ] Create `defaults/geyser.env` with Geyser-specific variables
- [ ] Update `entrypoint.sh` to source defaults files
- [ ] Test locally with docker-compose
- [ ] Verify all variables still work
- [ ] Commit changes

### Phase 2: Documentation (1 hour)
- [ ] Create `docs/ENVIRONMENT_VARIABLES.md`
- [ ] Document all variables by category
- [ ] Add examples for common scenarios
- [ ] Update README.md to reference new docs
- [ ] Create `.env.example` with all variables

### Phase 3: Cleanup (Optional, 2-3 hours)
- [ ] Audit 522 template variables
- [ ] Remove unused variables from templates
- [ ] Consolidate duplicate variables
- [ ] Update related documentation

### Phase 4: Testing (1 hour)
- [ ] Test fresh deployment
- [ ] Test environment variable changes
- [ ] Test force regeneration
- [ ] Test with minimal variables set
- [ ] Test with all plugins enabled

---

## Rollback Plan

If issues arise:

```bash
# Revert to previous entrypoint.sh
git checkout <previous-commit> scripts/entrypoint.sh

# Or keep both approaches temporarily
if [ -d "/defaults" ]; then
    # New approach
    source /defaults/core.env
else
    # Old approach (inline defaults)
    export GAMEMODE="${GAMEMODE:-survival}"
    # ...
fi
```

---

## Decision Required

**Question**: Which approach should we implement?

**Recommendation**: Hybrid approach (Option 1 + 4)
- Consolidated defaults files
- Organized by feature
- Conditional loading
- Well documented

**Next Steps**:
1. Get approval on approach
2. Create defaults/ structure
3. Implement in phases
4. Test thoroughly
5. Deploy incrementally

---

**Status**: 📋 PROPOSAL - AWAITING DECISION  
**Effort**: Low-Medium (4-6 hours total)  
**Risk**: Low (can rollback easily)  
**Benefit**: High (much better maintainability)
