# Harbor Registry Setup and Usage

This guide explains how to build and push your Minecraft server images to Harbor container registries with separate development and production environments.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Development Environment](#development-environment)
- [Production Environment](#production-environment)
- [Advanced Usage](#advanced-usage)
- [CI/CD Integration](#cicd-integration)

---

## Overview

This project supports two separate build environments:

- **Development**: https://harbor.dev.thebozic.com
  - Lower resource usage (1-2GB RAM)
  - Creative mode, peaceful difficulty
  - Offline mode (no authentication)
  - Debug logging enabled
  - Auto-pause when no players

- **Production**: https://harbor.prod.thebozic.com
  - High performance (4-8GB RAM)
  - Survival mode, hard difficulty
  - Online mode (authentication required)
  - Optimized JVM settings
  - Health checks enabled

---

## Prerequisites

### 1. Install Docker and Docker Compose
```bash
docker --version
docker-compose --version
```

### 2. Login to Harbor Registries

**Development Registry:**
```bash
docker login harbor.dev.thebozic.com
# Enter your Harbor credentials
```

**Production Registry:**
```bash
docker login harbor.prod.thebozic.com
# Enter your Harbor credentials
```

### 3. Ensure Harbor Project Exists
Make sure the `minecraft` project exists in both Harbor instances. If not, create it through the Harbor web UI.

---

## Quick Start

### Build and Push Development Image
```bash
# Build development image
./build.sh --env dev

# Build and push to Harbor dev registry
./build.sh --env dev --push harbor

# Build and push with version tag
./build.sh --env dev --push harbor --version 1.0.0
```

### Build and Push Production Image
```bash
# Build production image
./build.sh --env prod

# Build and push to Harbor prod registry
./build.sh --env prod --push harbor

# Build and push with version tag
./build.sh --env prod --push harbor --version 1.0.0
```

---

## Development Environment

### Building for Development

The development environment uses `Dockerfile.dev` and `docker-compose.dev.yml`:

```bash
# Build locally
./build.sh --env dev

# Build and push to Harbor dev
./build.sh --env dev --push harbor --version dev-$(date +%Y%m%d)

# Build multi-platform (ARM64 + AMD64)
./build.sh --env dev --push harbor --multiplatform
```

### Development Configuration

The development build includes:
- 1GB initial memory, 2GB max
- Creative mode, peaceful difficulty
- Offline mode (no Mojang authentication)
- PVP disabled
- View distance: 8 chunks
- Auto-pause enabled
- Debug logging

### Running Development Server

```bash
# Using docker-compose
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop server
docker-compose -f docker-compose.dev.yml down
```

### Development Image Tags

Development images are tagged as:
```
harbor.dev.thebozic.com/minecraft/minecraft-server:dev-latest
harbor.dev.thebozic.com/minecraft/minecraft-server:dev-1.0.0
harbor.dev.thebozic.com/minecraft/minecraft-server:dev-20250128
```

---

## Production Environment

### Building for Production

The production environment uses `Dockerfile.prod` and `docker-compose.prod.yml`:

```bash
# Build locally
./build.sh --env prod

# Build and push to Harbor prod
./build.sh --env prod --push harbor --version 1.0.0

# Build multi-platform (recommended for production)
./build.sh --env prod --push harbor --version 1.0.0 --multiplatform
```

### Production Configuration

The production build includes:
- 4GB initial memory, 8GB max
- Survival mode, hard difficulty
- Online mode (Mojang authentication required)
- PVP enabled
- View distance: 12 chunks
- Optimized JVM garbage collection
- Health checks enabled
- Resource limits

### Running Production Server

```bash
# Using docker-compose
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop server gracefully
docker-compose -f docker-compose.prod.yml down
```

### Production Image Tags

Production images are tagged as:
```
harbor.prod.thebozic.com/minecraft/minecraft-server:prod-latest
harbor.prod.thebozic.com/minecraft/minecraft-server:prod-1.0.0
harbor.prod.thebozic.com/minecraft/minecraft-server:prod-stable
```

---

## Advanced Usage

### Custom Harbor Project Name

```bash
# Use a different project name
./build.sh --env prod --push harbor --project my-custom-project
```

### Multi-Platform Builds

Build for both AMD64 and ARM64 architectures:

```bash
# Development
./build.sh --env dev --push harbor --multiplatform

# Production
./build.sh --env prod --push harbor --multiplatform --version 1.0.0
```

### Version Tagging Strategies

```bash
# Semantic versioning
./build.sh --env prod --push harbor --version 1.0.0

# Date-based versioning
./build.sh --env prod --push harbor --version $(date +%Y.%m.%d)

# Git commit hash
./build.sh --env prod --push harbor --version $(git rev-parse --short HEAD)

# Latest tag (default)
./build.sh --env prod --push harbor
```

### Pull and Run from Harbor

**Development:**
```bash
# Pull from Harbor dev
docker pull harbor.dev.thebozic.com/minecraft/minecraft-server:dev-latest

# Run directly
docker run -d -p 25565:25565 \
  -e EULA=TRUE \
  harbor.dev.thebozic.com/minecraft/minecraft-server:dev-latest
```

**Production:**
```bash
# Pull from Harbor prod
docker pull harbor.prod.thebozic.com/minecraft/minecraft-server:prod-1.0.0

# Run with docker-compose
docker-compose -f docker-compose.prod.yml up -d
```

---

## CI/CD Integration

### GitHub Actions Workflow

Create `.github/workflows/build-and-push.yml`:

```yaml
name: Build and Push to Harbor

on:
  push:
    branches:
      - main
      - develop
    tags:
      - 'v*'

env:
  HARBOR_DEV_URL: harbor.dev.thebozic.com
  HARBOR_PROD_URL: harbor.prod.thebozic.com
  HARBOR_PROJECT: mc-server

jobs:
  build-dev:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Harbor Dev
        uses: docker/login-action@v3
        with:
          registry: ${{ env.HARBOR_DEV_URL }}
          username: ${{ secrets.HARBOR_DEV_USERNAME }}
          password: ${{ secrets.HARBOR_DEV_PASSWORD }}
      
      - name: Build and push dev image
        run: |
          ./build.sh --env dev --push harbor --multiplatform \
            --version dev-${{ github.sha }}

  build-prod:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v')
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Harbor Prod
        uses: docker/login-action@v3
        with:
          registry: ${{ env.HARBOR_PROD_URL }}
          username: ${{ secrets.HARBOR_PROD_USERNAME }}
          password: ${{ secrets.HARBOR_PROD_PASSWORD }}
      
      - name: Extract version
        id: version
        run: |
          if [[ "${{ github.ref }}" == refs/tags/v* ]]; then
            VERSION=${GITHUB_REF#refs/tags/v}
          else
            VERSION=prod-latest
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
      
      - name: Build and push prod image
        run: |
          ./build.sh --env prod --push harbor --multiplatform \
            --version ${{ steps.version.outputs.version }}
```

### Required Secrets

Add these secrets to your GitHub repository:
- `HARBOR_DEV_USERNAME` - Harbor dev registry username
- `HARBOR_DEV_PASSWORD` - Harbor dev registry password
- `HARBOR_PROD_USERNAME` - Harbor prod registry username
- `HARBOR_PROD_PASSWORD` - Harbor prod registry password

---

## Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Key variables:
```bash
# Harbor URLs
HARBOR_DEV_URL=harbor.dev.thebozic.com
HARBOR_PROD_URL=harbor.prod.thebozic.com

# Production secrets
RCON_PASSWORD=your-secure-password

# Memory settings
PROD_MEMORY=4G
PROD_MAX_MEMORY=8G
```

---

## Troubleshooting

### Login Issues

**Problem:** Cannot login to Harbor registry
```bash
# Check if logged in
docker login harbor.dev.thebozic.com
docker login harbor.prod.thebozic.com

# Verify credentials in Harbor web UI
# Ensure user has push permissions to the project
```

### Build Failures

**Problem:** Build fails with "project not found"
- Create the `minecraft` project in Harbor web UI
- Or use `--project` flag with existing project name

**Problem:** Multi-platform build not working
```bash
# Setup buildx
docker buildx create --name multiplatform --use
docker buildx inspect --bootstrap
```

### Push Issues

**Problem:** "denied: requested access to the resource is denied"
- Ensure you're logged in to correct registry
- Verify user has push permissions in Harbor
- Check project exists and is accessible

### Image Pull Issues

**Problem:** Cannot pull image on deployment server
```bash
# Login on deployment server
docker login harbor.prod.thebozic.com

# Verify image exists
docker pull harbor.prod.thebozic.com/minecraft/minecraft-server:prod-latest
```

---

## Best Practices

### 1. Version Tagging
- Use semantic versioning for production releases
- Tag with git commit hash for traceability
- Always tag `latest` for current stable version

### 2. Security
- Change default RCON passwords in production
- Use `.env` files for secrets (never commit to git)
- Restrict Harbor project access to necessary users

### 3. Testing
- Always build and test locally before pushing
- Test dev images in development environment first
- Run full test suite before promoting to production

### 4. Deployment
- Use specific version tags in production (not `latest`)
- Implement blue-green deployments for zero downtime
- Keep previous versions available for quick rollback

### 5. Multi-Platform
- Build multi-platform images for flexibility
- Test on both AMD64 and ARM64 if supporting both

---

## Quick Reference

### Build Commands
```bash
# Development
./build.sh --env dev
./build.sh --env dev --push harbor
./build.sh --env dev --push harbor --version 1.0.0
./build.sh --env dev --push harbor --multiplatform

# Production
./build.sh --env prod
./build.sh --env prod --push harbor
./build.sh --env prod --push harbor --version 1.0.0
./build.sh --env prod --push harbor --multiplatform
```

### Run Commands
```bash
# Development
docker-compose -f docker-compose.dev.yml up -d
docker-compose -f docker-compose.dev.yml logs -f
docker-compose -f docker-compose.dev.yml down

# Production
docker-compose -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.prod.yml logs -f
docker-compose -f docker-compose.prod.yml down
```

### Login Commands
```bash
# Development registry
docker login harbor.dev.thebozic.com

# Production registry
docker login harbor.prod.thebozic.com
```

---

## Additional Resources

- [Harbor Documentation](https://goharbor.io/docs/)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [itzg/minecraft-server Documentation](https://github.com/itzg/docker-minecraft-server)
