# Harbor Push Guide - hephaestus-dev & hephaestus-prod

## Quick Start

### 1. Login to Harbor Registries

First, login to both Harbor registries:

```bash
# Login to development registry (hephaestus-dev)
docker login hephaestus-dev

# Login to production registry (hephaestus-prod)
docker login hephaestus-prod
```

You'll be prompted for username and password for each registry.

### 2. Push Images

Use the `push-to-harbor.sh` script to build and push images:

```bash
# Push development image
./push-to-harbor.sh --env dev --latest

# Push production image
./push-to-harbor.sh --env prod --latest

# Push to both registries at once
./push-to-harbor.sh --all --latest

# Push with custom version tag
./push-to-harbor.sh --env dev --version 1.0.0 --latest
```

## Detailed Commands

### Push Development Image

```bash
# Build and push dev image to hephaestus-dev
./push-to-harbor.sh --env dev --latest
```

**Result:**
- `hephaestus-dev/mc-server/minecraft-server:dev-TIMESTAMP`
- `hephaestus-dev/mc-server/minecraft-server:dev-COMMIT_HASH`
- `hephaestus-dev/mc-server/minecraft-server:dev-latest`

### Push Production Image

```bash
# Build and push prod image to hephaestus-prod
./push-to-harbor.sh --env prod --latest
```

**Result:**
- `hephaestus-prod/mc-server/minecraft-server:prod-TIMESTAMP`
- `hephaestus-prod/mc-server/minecraft-server:prod-COMMIT_HASH`
- `hephaestus-prod/mc-server/minecraft-server:prod-latest`

### Push to Both Registries

```bash
# Build and push both images to their respective registries
./push-to-harbor.sh --all --latest
```

**Result:**
- Dev images pushed to `hephaestus-dev`
- Prod images pushed to `hephaestus-prod`

### Custom Version Tags

```bash
# Use semantic versioning
./push-to-harbor.sh --env dev --version 1.0.0 --latest

# Use custom tag
VERSION=2024-release ./push-to-harbor.sh --env prod --latest
```

## Image Tags Explained

Each push creates **3 tags**:

1. **Version Tag** (timestamp or custom)
   - Example: `dev-20251130-143052` or `dev-1.0.0`
   - Purpose: Specific version identification

2. **Git Commit Tag**
   - Example: `dev-a1b2c3d`
   - Purpose: Trace back to exact source code

3. **Latest Tag** (with `--latest` flag)
   - Example: `dev-latest` or `prod-latest`
   - Purpose: Always points to most recent build

## Pulling Images from Harbor

### From Development Registry

```bash
# Pull specific version
docker pull hephaestus-dev/mc-server/minecraft-server:dev-20251130-143052

# Pull latest
docker pull hephaestus-dev/mc-server/minecraft-server:dev-latest

# Pull by git commit
docker pull hephaestus-dev/mc-server/minecraft-server:dev-a1b2c3d
```

### From Production Registry

```bash
# Pull specific version
docker pull hephaestus-prod/mc-server/minecraft-server:prod-1.0.0

# Pull latest
docker pull hephaestus-prod/mc-server/minecraft-server:prod-latest

# Pull by git commit
docker pull hephaestus-prod/mc-server/minecraft-server:prod-a1b2c3d
```

## Using Harbor Images in Docker Compose

### Development with Harbor Image

Update `docker-compose.dev.yml`:

```yaml
services:
  minecraft-dev:
    image: hephaestus-dev/mc-server/minecraft-server:dev-latest
    # Remove the 'build:' section when using pre-built images
    container_name: minecraft-server-dev
    # ... rest of config
```

### Production with Harbor Image

Update `docker-compose.prod.yml`:

```yaml
services:
  minecraft-prod:
    image: hephaestus-prod/mc-server/minecraft-server:prod-latest
    # Remove the 'build:' section when using pre-built images
    container_name: minecraft-server-prod
    # ... rest of config
```

## Workflow Examples

### Release Workflow (Production)

```bash
# 1. Build and test locally
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
# Test the server...
docker-compose -f docker-compose.prod.yml down

# 2. Push to Harbor with version tag
./push-to-harbor.sh --env prod --version 1.0.0 --latest

# 3. Update production server
# SSH to production server
docker-compose pull
docker-compose up -d
```

### Continuous Development Workflow

```bash
# After making changes, push new dev image
./push-to-harbor.sh --env dev --latest

# On development server, pull and restart
docker-compose -f docker-compose.dev.yml pull
docker-compose -f docker-compose.dev.yml up -d
```

### Both Environments at Once

```bash
# Push to both registries with version tag
./push-to-harbor.sh --all --version 1.1.0 --latest
```

## Troubleshooting

### Login Issues

If you get authentication errors:

```bash
# Check if logged in
docker info | grep Username

# Logout and login again
docker logout hephaestus-dev
docker login hephaestus-dev

docker logout hephaestus-prod
docker login hephaestus-prod
```

### Connection Issues

If you can't connect to Harbor:

```bash
# Check if hostname resolves
ping hephaestus-dev
ping hephaestus-prod

# Check if Harbor is accessible
curl -k https://hephaestus-dev/api/v2.0/systeminfo
curl -k https://hephaestus-prod/api/v2.0/systeminfo
```

### Build Issues

If build fails:

```bash
# Check Docker is running
docker ps

# Check disk space
df -h

# Check Docker images
docker images

# Clean up if needed
docker system prune -a
```

### Push Issues

If push fails:

```bash
# Check you're logged in
docker login hephaestus-dev

# Check network connectivity
docker pull hello-world

# Try manual push
docker push hephaestus-dev/mc-server/minecraft-server:dev-latest
```

## Harbor Web UI

Access Harbor web interfaces:

- **Development**: https://hephaestus-dev
- **Production**: https://hephaestus-prod

From the web UI you can:
- Browse pushed images
- View tags and metadata
- Manage vulnerabilities
- Configure webhooks
- Set retention policies

## Environment Variables

The script uses these environment variables (optional):

```bash
# Custom version tag
export VERSION=1.0.0
./push-to-harbor.sh --env prod

# Custom git commit (auto-detected by default)
export GIT_COMMIT=abc123
./push-to-harbor.sh --env dev
```

## Script Options Reference

```
Usage: ./push-to-harbor.sh [OPTIONS]

Options:
    --env <env>        Environment: dev or prod (required unless --all)
    --version <ver>    Version tag (default: timestamp YYYYMMDD-HHMMSS)
    --latest           Also tag as 'latest' (recommended)
    --all              Build and push to both dev and prod
    --help             Show help message

Examples:
    ./push-to-harbor.sh --env dev
    ./push-to-harbor.sh --env prod --version 1.0.0 --latest
    ./push-to-harbor.sh --all --latest
```

## Best Practices

1. **Always use `--latest` flag** for production releases
2. **Use semantic versioning** for production (e.g., 1.0.0, 1.1.0)
3. **Use timestamps** for development builds (automatic)
4. **Test locally before pushing** to production registry
5. **Tag releases** in git to match image versions
6. **Document changes** in CHANGELOG.md
7. **Keep dev and prod separate** - don't cross-contaminate

## Next Steps

After pushing images:

1. **Update docker-compose files** to use Harbor images
2. **Deploy to servers** using the Harbor images
3. **Monitor** Harbor for vulnerabilities
4. **Set up retention policies** to clean old images
5. **Configure webhooks** for automated deployments

## Support

For issues or questions:
- Check Harbor logs in the web UI
- Review `push-to-harbor.sh` script
- Check Docker daemon logs: `journalctl -u docker`
- Verify network connectivity to Harbor registries
