# Troubleshooting Guide

## Common Issues and Solutions

### 1. Yggdrasil Key Fetcher Errors

**Symptom:**
```
[Yggdrasil Key Fetcher/ERROR]: Got an error with a html body connecting to https://api.minecraftservices.com/publickeys
[Yggdrasil Key Fetcher/ERROR]: Failed to request yggdrasil public key
```

**Cause:**
- **HTTP 429 Rate Limiting**: Mojang's authentication API rate-limits excessive requests
- **ONLINE_MODE=false**: Server tries to fetch keys even when offline mode is enabled
- **Frequent Restarts**: Multiple container restarts during development trigger rate limits

**Solutions:**

1. **Set online-mode=true** (Recommended for production):
   - Update `.env.dev` or `.env.prod`: `ONLINE_MODE=true`
   - Ensure docker-compose doesn't override this value
   - Restart container: `docker-compose -f docker-compose.dev.yml down && docker-compose -f docker-compose.dev.yml up -d`

2. **Wait for rate limit to expire** (Development):
   - Rate limits typically reset after 10-60 minutes
   - If `ONLINE_MODE=false`, this error doesn't affect gameplay
   - Error is cosmetic - server functions normally

3. **Use a VPN or different IP** (Emergency):
   - If rate-limited for extended periods
   - Switch network or wait for rate limit reset

### 2. Environment Variables Not Applied

**Symptom:**
- Variables set in `.env.dev` are not reflected in the running container
- `docker exec container printenv VAR` shows wrong value

**Cause:**
- Docker Compose `environment:` section **overrides** `env_file:` values
- Hardcoded values in docker-compose take precedence

**Solution:**
1. Check `docker-compose.dev.yml` for hardcoded environment variables
2. Remove or comment out conflicting variables in the `environment:` section
3. Ensure `env_file:` directive is present:
   ```yaml
   services:
     minecraft-dev:
       env_file:
         - .env.dev
       environment:
         # Only put Docker-specific or non-configurable vars here
         EULA: "TRUE"
         TYPE: "SPIGOT"
         # Don't override vars from .env.dev
   ```

### 3. BlueMap "Missing Resources" Warning

**Symptom:**
```
[BlueMap] BlueMap is missing important resources!
[BlueMap] You must accept the required file download in order for BlueMap to work!
```

**Cause:**
- `BLUEMAP_ACCEPT_DOWNLOAD=false` in generated config
- Environment variable not properly passed to container

**Solution:**
1. Set in `.env.dev`:
   ```bash
   BLUEMAP_ACCEPT_DOWNLOAD=true
   ```

2. Ensure docker-compose loads env_file:
   ```yaml
   env_file:
     - .env.dev
   ```

3. **Manual fix** (if config already generated):
   ```bash
   docker exec minecraft-server-dev sed -i 's/accept-download: false/accept-download: true/' /data/plugins/BlueMap/core.conf
   docker exec minecraft-server-dev rcon-cli --password devpass "bluemap reload"
   ```

4. **Clean restart** (regenerates all configs):
   ```bash
   docker-compose -f docker-compose.dev.yml down
   rm -rf ./data-dev/plugins/BlueMap/
   docker-compose -f docker-compose.dev.yml up -d
   ```

### 4. SELinux Permission Denied (Fedora/RHEL/CentOS)

**Symptom:**
```
chown: cannot read directory '/data': Permission denied
/data/eula.txt: Permission denied
```

**Cause:**
- SELinux in Enforcing mode blocks Docker from accessing bind-mounted volumes
- Missing SELinux context labels on volume mounts

**Solution:**
Add `:Z` or `:z` flags to volume mounts in docker-compose:

```yaml
volumes:
  # Private volumes (one container only) - use :Z
  - ./data-dev:/data:Z
  - ./logs-dev:/data/logs:Z
  
  # Shared read-only volumes - use :z
  - ./plugins:/plugins:ro,z
  - ./datapacks:/datapacks:ro,z
```

See [FEDORA_SELINUX.md](./FEDORA_SELINUX.md) for detailed information.

### 5. Container Exits Immediately / Restart Loop

**Symptom:**
- Container status shows "Restarting" constantly
- `docker logs` shows errors and container exits

**Common Causes:**

1. **EULA not accepted**:
   - Ensure `EULA: "TRUE"` in docker-compose environment

2. **Volume permission issues**:
   - Check volume ownership: `ls -la ./data-dev`
   - Should be owned by uid=1000 or have proper SELinux labels
   - Fix: `sudo chown -R 1000:1000 ./data-dev` or add `:Z` flag

3. **Invalid environment variables**:
   - Check for typos in .env files
   - Verify all required variables are set

4. **Port conflicts**:
   - Ensure ports 25565, 25575 are not already in use
   - Check: `sudo netstat -tulpn | grep -E '25565|25575'`

**Debug steps:**
```bash
# Check container logs
docker logs minecraft-server-dev --tail 100

# Check container status
docker ps -a --filter "name=minecraft-server-dev"

# Check environment variables in container
docker exec minecraft-server-dev printenv | grep -E "EULA|TYPE|VERSION|ONLINE_MODE"

# Interactive shell for debugging
docker exec -it minecraft-server-dev bash
```

### 6. Plugins Not Loading

**Symptom:**
- Plugins directory populated but plugins don't load
- No plugin messages in server logs

**Cause:**
- Plugins are read-only mounted but need write access for config generation
- Wrong plugin versions for server version

**Solution:**

1. Check plugin compatibility:
   - Spigot 1.21.5 requires plugins built for 1.21+
   - Check plugin versions in `./plugins/` directory

2. Verify volume mounts:
   ```yaml
   volumes:
     - ./plugins:/plugins:ro,z  # Plugins are read-only
   ```

3. Check plugin logs:
   ```bash
   docker exec minecraft-server-dev cat /data/logs/latest.log | grep -i "plugin\|loading"
   ```

### 7. Templates Not Processed

**Symptom:**
- Config files contain `${VARIABLE}` strings
- Settings from .env not applied

**Cause:**
- Entrypoint script didn't run or failed
- Environment variables not set at template processing time

**Solution:**

1. Check entrypoint execution:
   ```bash
   docker logs minecraft-server-dev --tail 200 | grep -A10 "Template Processor"
   ```

2. Verify variables are set:
   ```bash
   docker exec minecraft-server-dev printenv | grep BLUEMAP
   ```

3. Manually reprocess templates:
   ```bash
   docker exec minecraft-server-dev bash -c 'cd /templates && /entrypoint.sh'
   ```

4. Clean restart:
   ```bash
   docker-compose -f docker-compose.dev.yml down
   rm -rf ./data-dev/plugins/*/config.yml
   docker-compose -f docker-compose.dev.yml up -d
   ```

## Getting Help

If you encounter issues not covered here:

1. **Check container logs**:
   ```bash
   docker logs minecraft-server-dev -f
   ```

2. **Check server logs**:
   ```bash
   docker exec minecraft-server-dev tail -f /data/logs/latest.log
   ```

3. **Verify configuration**:
   ```bash
   docker exec minecraft-server-dev cat /data/server.properties
   docker exec minecraft-server-dev cat /data/plugins/PluginName/config.yml
   ```

4. **Check resource usage**:
   ```bash
   docker stats minecraft-server-dev
   ```

5. **Interactive debugging**:
   ```bash
   docker exec -it minecraft-server-dev bash
   ```

## Useful Commands

```bash
# Restart server
docker-compose -f docker-compose.dev.yml restart

# View live logs
docker logs -f minecraft-server-dev

# Execute RCON commands
docker exec minecraft-server-dev rcon-cli --password devpass "list"

# Check server status
docker exec minecraft-server-dev rcon-cli --password devpass "tps"

# Reload BlueMap
docker exec minecraft-server-dev rcon-cli --password devpass "bluemap reload"

# Stop server gracefully
docker-compose -f docker-compose.dev.yml down

# Nuclear option - full reset
docker-compose -f docker-compose.dev.yml down
rm -rf ./data-dev/*
docker-compose -f docker-compose.dev.yml up -d
```
