# Issue Resolution Summary

## Date: 2025-11-30

### Issues Identified and Fixed

#### 1. ✅ BlueMap "Accept Download" Warning
**Problem:**
- BlueMap showing "missing resources" warning at startup
- `accept-download: false` in generated config despite `BLUEMAP_ACCEPT_DOWNLOAD=true` in `.env.dev`

**Root Cause:**
- Docker Compose `environment:` section was setting hardcoded default values
- These hardcoded values were overriding the `env_file:` values from `.env.dev`
- Environment variables take precedence over env_file in Docker Compose

**Solution Applied:**
1. Added `env_file: - .env.dev` to docker-compose.dev.yml
2. Removed hardcoded plugin environment variables from `environment:` section
3. Manually fixed existing BlueMap config: `sed -i 's/accept-download: false/accept-download: true/'`
4. Reloaded BlueMap: `rcon-cli "bluemap reload"`

**Result:**
- BlueMap now downloads resources successfully
- Warning eliminated from logs
- Template processing works correctly for future container starts

---

#### 2. ✅ Yggdrasil Key Fetcher Errors
**Problem:**
```
[Yggdrasil Key Fetcher/ERROR]: Got an error with a html body connecting to https://api.minecraftservices.com/publickeys
[Yggdrasil Key Fetcher/ERROR]: Failed to request yggdrasil public key
```

**Root Cause:**
- `ONLINE_MODE=false` was hardcoded in docker-compose.dev.yml
- Server was set to offline mode but still attempting to fetch Mojang authentication keys
- Multiple container restarts triggered Mojang API rate limiting (HTTP 429)
- `.env.dev` had `ONLINE_MODE=true` but was being overridden

**Solution Applied:**
1. Removed `ONLINE_MODE: "false"` from docker-compose.dev.yml `environment:` section
2. Allowed `ONLINE_MODE=true` from `.env.dev` to take effect
3. Restarted container to regenerate server.properties with correct value

**Result:**
- Server now properly runs in online mode (`online-mode=true`)
- Yggdrasil errors completely eliminated
- Mojang authentication working correctly

---

#### 3. ✅ SELinux Volume Permission Issues (Fedora)
**Problem:**
```
chown: cannot read directory '/data': Permission denied
/data/eula.txt: Permission denied
```

**Root Cause:**
- Fedora Linux with SELinux in Enforcing mode
- Bind-mounted volumes lacked proper SELinux context labels
- Container (uid=1000) couldn't write to volumes owned by root

**Solution Applied:**
1. Added `:Z` flag to private read-write volumes (data, logs)
2. Added `:z` flag to shared read-only volumes (plugins, datapacks, config)
3. Updated both docker-compose.dev.yml and docker-compose.prod.yml

**Result:**
- Container starts successfully on Fedora
- No permission denied errors
- SELinux remains in Enforcing mode (secure)

---

### Configuration Changes Summary

#### Files Modified:

1. **docker-compose.dev.yml**
   - Added `env_file: - .env.dev`
   - Removed hardcoded `ONLINE_MODE: "false"`
   - Removed plugin-specific environment variable overrides
   - Added SELinux volume labels (`:Z` and `:z`)

2. **docker-compose.prod.yml**
   - Added `env_file: - .env.prod`
   - Added SELinux volume labels (`:Z` and `:z`)

3. **.env.dev**
   - Removed duplicate `BLUEMAP_ACCEPT_DOWNLOAD=true` entry
   - Kept `ONLINE_MODE=true`
   - All plugin settings remain intact

4. **New Documentation Created**
   - `docs/FEDORA_SELINUX.md` - Complete SELinux configuration guide
   - `docs/TROUBLESHOOTING.md` - Comprehensive troubleshooting reference
   - `docs/DEV_IMAGE_BUILD.md` - Development image build documentation

---

### Current Server Status

**Container**: minecraft-server-dev
- **Status**: ✅ Up 3 minutes (healthy)
- **Image**: minecraft-server:dev-latest (889MB)
- **Server Version**: Spigot 1.21.5
- **Java Version**: 21

**Configuration**:
- **online-mode**: `true` ✅
- **gamemode**: `creative`
- **difficulty**: `peaceful`
- **max-players**: `10`
- **server-port**: `25565`
- **RCON port**: `25575`

**Plugins Loaded**:
- ✅ BlueMap v5.7 (downloading resources successfully)
- ✅ DiscordSRV v1.29.0
- ✅ Geyser-Spigot (Bedrock support)
- ✅ Floodgate (Bedrock authentication)
- ⚠️ Geyser warning about Java 1.21.9 (cosmetic, works fine)

**Templates Processed**: 15/15 ✅
- 5 server configuration files
- 10 plugin configuration files

**Ports Exposed**:
- `25565` - Minecraft Java Edition
- `25575` - RCON
- `19132` - Bedrock Edition (Geyser)
- `8100` - BlueMap Web UI (when available)

---

### Environment Variable Precedence (Lesson Learned)

In Docker Compose, **order of precedence** (highest to lowest):

1. 🥇 **`environment:` section** - Hardcoded values in docker-compose.yml
2. 🥈 **`env_file:` directive** - Variables from .env files
3. 🥉 **Shell environment** - Exported variables in terminal
4. 🏅 **`.env` file** - Default .env in same directory as docker-compose.yml

**Best Practice**:
- Use `env_file:` for user-configurable values (`.env.dev`, `.env.prod`)
- Use `environment:` only for constants that should never change (`EULA: "TRUE"`, `TYPE: "SPIGOT"`)
- Add comments like `# VAR comes from .env.dev` when variables should be in env_file

---

### Testing Checklist

- [x] Container starts successfully
- [x] No permission errors (SELinux)
- [x] Online mode enabled (`online-mode=true`)
- [x] No Yggdrasil authentication errors
- [x] BlueMap resources downloading
- [x] All templates processed correctly
- [x] Environment variables applied from .env.dev
- [x] RCON accessible
- [x] Server responds to pings
- [x] Health check passing

---

### Next Steps (Optional)

1. **Test BlueMap Web UI**:
   ```bash
   # Wait for BlueMap to finish resource download and initial render
   # Then access: http://localhost:8100
   ```

2. **Test Bedrock Edition Connection**:
   ```bash
   # Connect from Minecraft Bedrock Edition
   # Server: localhost:19132
   ```

3. **Configure DiscordSRV**:
   - Add `DISCORD_BOT_TOKEN` to `.env.dev`
   - Add `DISCORD_CHAT_CHANNEL_ID` to `.env.dev`
   - Restart container

4. **Production Deployment**:
   - Copy `.env.prod.example` to `.env.prod`
   - Configure production settings
   - Build production image: `./build.sh prod`
   - Start: `docker-compose -f docker-compose.prod.yml up -d`

---

### Documentation References

- **SELinux Configuration**: [docs/FEDORA_SELINUX.md](./FEDORA_SELINUX.md)
- **Troubleshooting Guide**: [docs/TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- **Plugin Configuration**: [docs/PLUGIN_MIGRATION_1.21.5.md](./PLUGIN_MIGRATION_1.21.5.md)
- **Template System**: [docs/TEMPLATING_GUIDE.md](./TEMPLATING_GUIDE.md)
- **Build Process**: [docs/DEV_IMAGE_BUILD.md](./DEV_IMAGE_BUILD.md)
