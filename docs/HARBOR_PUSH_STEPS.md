# Step-by-Step: Push to Harbor

## Prerequisites Checklist

Before pushing, ensure:
- [ ] Docker is running
- [ ] You have Harbor credentials for both registries
- [ ] Network connectivity to hephaestus-dev and hephaestus-prod
- [ ] Images are built locally (or will be built by script)

## Step 1: Login to Harbor Registries

### Login to Development Registry

```bash
docker login hephaestus-dev
```

When prompted, enter:
- **Username**: Your Harbor username
- **Password**: Your Harbor password

### Login to Production Registry

```bash
docker login hephaestus-prod
```

When prompted, enter:
- **Username**: Your Harbor username
- **Password**: Your Harbor password

### Verify Login

```bash
# Check if logged in
cat ~/.docker/config.json | grep hephaestus
```

## Step 2: Choose Your Push Strategy

### Option A: Push Development Only

```bash
cd /home/luckyprayer/mc-server-1
./push-to-harbor.sh --env dev --latest
```

**What this does:**
1. Builds the development image using `Dockerfile.dev`
2. Tags it with:
   - Timestamp (e.g., `dev-20251130-143052`)
   - Git commit (e.g., `dev-a1b2c3d`)
   - Latest tag (`dev-latest`)
3. Pushes all tags to `hephaestus-dev/mc-server/minecraft-server`

**Duration:** ~5-10 minutes

### Option B: Push Production Only

```bash
cd /home/luckyprayer/mc-server-1
./push-to-harbor.sh --env prod --latest
```

**What this does:**
1. Builds the production image using `Dockerfile.prod`
2. Tags it with:
   - Timestamp (e.g., `prod-20251130-143052`)
   - Git commit (e.g., `prod-a1b2c3d`)
   - Latest tag (`prod-latest`)
3. Pushes all tags to `hephaestus-prod/mc-server/minecraft-server`

**Duration:** ~5-10 minutes

### Option C: Push Both (Recommended)

```bash
cd /home/luckyprayer/mc-server-1
./push-to-harbor.sh --all --latest
```

**What this does:**
1. Builds both dev and prod images
2. Tags each with timestamp, git commit, and latest
3. Pushes dev images to `hephaestus-dev`
4. Pushes prod images to `hephaestus-prod`

**Duration:** ~10-20 minutes

### Option D: Custom Version Tag

```bash
cd /home/luckyprayer/mc-server-1
./push-to-harbor.sh --all --version 1.0.0 --latest
```

**What this does:**
1. Same as Option C, but uses `1.0.0` instead of timestamp
2. Creates tags like:
   - `dev-1.0.0` and `prod-1.0.0`
   - `dev-a1b2c3d` and `prod-a1b2c3d`
   - `dev-latest` and `prod-latest`

**Use for:** Production releases with semantic versioning

## Step 3: Monitor the Push

The script will show progress:

```
ℹ ======================================
ℹ Processing dev environment
ℹ Registry: hephaestus-dev
ℹ Version: 20251130-143052
ℹ Git Commit: a1b2c3d
ℹ ======================================

ℹ Logging in to hephaestus-dev...
✓ Logged in to hephaestus-dev

ℹ Building dev image...
[Docker build output...]
✓ Built minecraft-server:dev-latest

ℹ Tagging images for hephaestus-dev...
✓ Tagged images

ℹ Pushing to hephaestus-dev...
✓ Pushed hephaestus-dev/mc-server/minecraft-server:dev-20251130-143052
✓ Pushed hephaestus-dev/mc-server/minecraft-server:dev-a1b2c3d
✓ Pushed hephaestus-dev/mc-server/minecraft-server:dev-latest

✓ Completed dev environment push to hephaestus-dev
```

## Step 4: Verify the Push

### Check in Harbor Web UI

**Development:**
1. Open https://hephaestus-dev in your browser
2. Login with your credentials
3. Navigate to Projects → mc-server → minecraft-server
4. Verify you see the new tags

**Production:**
1. Open https://hephaestus-prod in your browser
2. Login with your credentials
3. Navigate to Projects → mc-server → minecraft-server
4. Verify you see the new tags

### Check via Command Line

```bash
# Check dev registry
docker pull hephaestus-dev/mc-server/minecraft-server:dev-latest
docker images | grep hephaestus-dev

# Check prod registry
docker pull hephaestus-prod/mc-server/minecraft-server:prod-latest
docker images | grep hephaestus-prod
```

## Step 5: Update Docker Compose (Optional)

If you want to use the Harbor images instead of building locally, update your docker-compose files:

### docker-compose.dev.yml

**Change from:**
```yaml
services:
  minecraft-dev:
    build:
      context: .
      dockerfile: Dockerfile.dev
    image: minecraft-server:dev-latest
```

**To:**
```yaml
services:
  minecraft-dev:
    image: hephaestus-dev/mc-server/minecraft-server:dev-latest
    # Remove the 'build:' section
```

### docker-compose.prod.yml

**Change from:**
```yaml
services:
  minecraft-prod:
    build:
      context: .
      dockerfile: Dockerfile.prod
    image: minecraft-server:prod-latest
```

**To:**
```yaml
services:
  minecraft-prod:
    image: hephaestus-prod/mc-server/minecraft-server:prod-latest
    # Remove the 'build:' section
```

## Common Issues and Solutions

### Issue: Login Failed

**Error:**
```
Error response from daemon: Get "https://hephaestus-dev/v2/": dial tcp: lookup hephaestus-dev: no such host
```

**Solution:**
Check if hostnames resolve:
```bash
ping hephaestus-dev
ping hephaestus-prod
```

If they don't resolve, you may need to:
1. Add them to `/etc/hosts` (requires sudo)
2. Or use IP addresses instead
3. Or update DNS configuration

### Issue: Authentication Required

**Error:**
```
unauthorized: authentication required
```

**Solution:**
```bash
# Logout and login again
docker logout hephaestus-dev
docker login hephaestus-dev

docker logout hephaestus-prod
docker login hephaestus-prod
```

### Issue: Project Not Found

**Error:**
```
repository mc-server/minecraft-server not found
```

**Solution:**
1. Login to Harbor web UI
2. Create project named `mc-server`
3. Make it public or ensure you have access
4. Try push again

### Issue: Build Failed

**Error:**
```
ERROR: failed to solve: failed to compute cache key
```

**Solution:**
```bash
# Clean Docker cache and rebuild
docker system prune -a
./push-to-harbor.sh --env dev --latest
```

### Issue: Network Timeout

**Error:**
```
net/http: TLS handshake timeout
```

**Solution:**
```bash
# Check network connectivity
ping hephaestus-dev

# Increase Docker timeout
export DOCKER_CLIENT_TIMEOUT=300
export COMPOSE_HTTP_TIMEOUT=300

# Try again
./push-to-harbor.sh --env dev --latest
```

## What Happens Next?

After successfully pushing images:

1. **Images are available** in Harbor registries
2. **Other servers can pull** them without rebuilding
3. **CI/CD pipelines** can reference these images
4. **Teams can collaborate** using the same images

## Quick Reference Commands

```bash
# Login to registries
docker login hephaestus-dev
docker login hephaestus-prod

# Push dev only
./push-to-harbor.sh --env dev --latest

# Push prod only
./push-to-harbor.sh --env prod --latest

# Push both
./push-to-harbor.sh --all --latest

# Push with version
./push-to-harbor.sh --all --version 1.0.0 --latest

# Pull from Harbor
docker pull hephaestus-dev/mc-server/minecraft-server:dev-latest
docker pull hephaestus-prod/mc-server/minecraft-server:prod-latest

# Run from Harbor image
docker-compose -f docker-compose.dev.yml pull
docker-compose -f docker-compose.dev.yml up -d
```

## Ready to Push?

Execute this command to push both images:

```bash
cd /home/luckyprayer/mc-server-1
./push-to-harbor.sh --all --latest
```

This will build and push both development and production images to their respective Harbor registries!
