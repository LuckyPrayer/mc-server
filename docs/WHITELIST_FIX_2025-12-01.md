# Whitelist Configuration Fix

**Date**: December 1, 2025  
**Issue**: Players unable to join with "You are not whitelisted on this server!" message  
**Status**: ✅ FIXED

---

## Problem

Players were unable to join the Minecraft server, receiving the error message:
> "You are not whitelisted on this server!"

This was caused by whitelist enforcement being enabled by default in the production configuration.

---

## Solution

Disabled whitelist enforcement by default across the entire codebase.

### Changes Made

#### 1. scripts/entrypoint.sh
Added default values for whitelist-related environment variables:

```bash
# Server whitelist defaults (disabled by default for easier access)
export WHITELIST_ENABLED="${WHITELIST_ENABLED:-false}"
export ENFORCE_WHITELIST="${ENFORCE_WHITELIST:-false}"
export WHITELIST_MESSAGE="${WHITELIST_MESSAGE:-You are not whitelisted on this server!}"
```

**Effect**: If no environment variables are set, whitelist will be **disabled** by default.

#### 2. docker-compose.prod.yml
Changed from hardcoded `"true"` to environment variable with default:

**Before**:
```yaml
# Production settings
ENFORCE_WHITELIST: "true"
WHITELIST: ""
```

**After**:
```yaml
# Production settings
# Whitelist disabled by default - set ENFORCE_WHITELIST=true and WHITELIST_ENABLED=true to enable
ENFORCE_WHITELIST: "${ENFORCE_WHITELIST:-false}"
WHITELIST_ENABLED: "${WHITELIST_ENABLED:-false}"
```

**Effect**: Production environment now defaults to whitelist **disabled**.

---

## How to Enable Whitelist (If Needed)

If you want to enable whitelist in the future:

### Option 1: Environment Variables

Set in your `.env` file or docker-compose environment:

```bash
WHITELIST_ENABLED=true
ENFORCE_WHITELIST=true
```

### Option 2: Docker Compose Override

Edit `docker-compose.prod.yml`:

```yaml
environment:
  WHITELIST_ENABLED: "true"
  ENFORCE_WHITELIST: "true"
```

### Option 3: In-Game Commands

You can also enable whitelist while the server is running:

```bash
# Connect via RCON
docker exec minecraft-server rcon-cli

# Enable whitelist
whitelist on

# Add players
whitelist add PlayerName

# Check whitelist
whitelist list
```

---

## Verification

### Check Current Settings

```bash
# Check environment variables
docker exec minecraft-server printenv | grep WHITELIST

# Expected output:
# WHITELIST_ENABLED=false
# ENFORCE_WHITELIST=false
# WHITELIST_MESSAGE=You are not whitelisted on this server!

# Check server.properties
docker exec minecraft-server grep -E "white-list|enforce-whitelist" /data/server.properties

# Expected output:
# white-list=false
# enforce-whitelist=false
```

### Test Player Connection

1. Try connecting to the server with any Minecraft client
2. You should be able to join without being on the whitelist
3. No "You are not whitelisted" error should appear

---

## Deployment

### Quick Fix (Existing Deployment)

If you need to fix an existing deployment immediately without rebuilding:

```bash
# Stop the server
docker-compose down

# Edit environment or docker-compose file to set:
# ENFORCE_WHITELIST=false
# WHITELIST_ENABLED=false

# Restart
docker-compose up -d

# Or force config regeneration:
MINECRAFT_FORCE_CONFIG_REGEN=true docker-compose up -d
```

### Proper Deployment (Rebuild Image)

```bash
# 1. Build new image with the fix
./build.sh --env prod --push harbor

# 2. Pull and restart
docker-compose pull
docker-compose up -d

# 3. Verify
docker logs minecraft-server | grep "Template Processor"
docker exec minecraft-server grep white-list /data/server.properties
```

---

## Related Configuration

### server.properties Template

The whitelist settings in `templates/server/server.properties.template`:

```properties
white-list=${WHITELIST_ENABLED}
enforce-whitelist=${ENFORCE_WHITELIST}
```

These now default to `false` when processed by the entrypoint script.

### spigot.yml Template

Whitelist rejection message in `templates/server/spigot.yml.template`:

```yaml
messages:
  whitelist: ${WHITELIST_MESSAGE}
```

Defaults to: "You are not whitelisted on this server!"

---

## Best Practices

### Development Environment
- Keep whitelist **disabled** (default)
- Easier testing and development
- Anyone can join to test

### Production Environment
- **Disabled by default** (as of this fix)
- Enable only if needed for private servers
- Use whitelist for controlled access

### Hybrid Approach
- Keep whitelist disabled initially
- Enable later when community is established
- Add trusted players gradually

---

## Troubleshooting

### Still Getting Whitelist Error After Fix

**Possible Causes**:

1. **Old config cached**: Server.properties wasn't regenerated
   ```bash
   # Force regeneration
   MINECRAFT_FORCE_CONFIG_REGEN=true docker-compose restart
   ```

2. **Whitelist enabled in-game**: Someone ran `/whitelist on` command
   ```bash
   # Connect via RCON and disable
   docker exec minecraft-server rcon-cli whitelist off
   ```

3. **Wrong environment file**: Using old .env with WHITELIST_ENABLED=true
   ```bash
   # Check .env file
   cat .env | grep WHITELIST
   
   # Remove or comment out:
   # WHITELIST_ENABLED=true
   # ENFORCE_WHITELIST=true
   ```

4. **Base image has whitelist.json**: Existing whitelist file from previous config
   ```bash
   # Remove whitelist file
   docker exec minecraft-server rm -f /data/whitelist.json
   docker-compose restart
   ```

### Verify Fix Was Applied

```bash
# Check entrypoint has defaults
docker exec minecraft-server cat /scripts/entrypoint.sh | grep "WHITELIST_ENABLED="

# Should show:
# export WHITELIST_ENABLED="${WHITELIST_ENABLED:-false}"

# Check docker-compose
docker compose config | grep WHITELIST

# Should show:
# ENFORCE_WHITELIST: "false"
# WHITELIST_ENABLED: "false"
```

---

## Related Files

- `scripts/entrypoint.sh` - Default environment variables
- `docker-compose.prod.yml` - Production configuration
- `templates/server/server.properties.template` - Server properties template
- `templates/server/spigot.yml.template` - Spigot messages template

---

## Additional Notes

### Why Disabled by Default?

1. **Easier onboarding**: New players can join immediately
2. **Development friendly**: No need to manage whitelist during testing
3. **Community building**: Lower barrier to entry
4. **Opt-in security**: Enable when needed, not forced

### When to Enable Whitelist?

- Private servers for friends only
- Controlled community with verification process
- Protection against griefing
- Server capacity management

---

**Status**: ✅ FIXED  
**Impact**: All new deployments will have whitelist disabled  
**Migration**: Existing deployments need rebuild or manual config update  
**Risk**: Low - can easily re-enable if needed
