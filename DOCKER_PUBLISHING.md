# Building and Publishing the Docker Container

This guide explains how to build your Minecraft server Docker image and push it to a container registry.

## Table of Contents
- [Docker Hub](#docker-hub)
- [GitHub Container Registry](#github-container-registry)
- [Quick Commands](#quick-commands)

---

## Docker Hub

### Prerequisites
1. Create a Docker Hub account at https://hub.docker.com
2. Login to Docker Hub from your terminal:
   ```bash
   docker login
   ```

### Building the Image

```bash
# Build for your platform
docker build -t YOUR_USERNAME/minecraft-server:latest .

# Build for multiple platforms (ARM64, AMD64)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t YOUR_USERNAME/minecraft-server:latest \
  --push .
```

### Tagging the Image

```bash
# Tag with version
docker tag YOUR_USERNAME/minecraft-server:latest YOUR_USERNAME/minecraft-server:1.0.0

# Tag with Minecraft version
docker tag YOUR_USERNAME/minecraft-server:latest YOUR_USERNAME/minecraft-server:1.21
```

### Pushing to Docker Hub

```bash
# Push latest tag
docker push YOUR_USERNAME/minecraft-server:latest

# Push specific version
docker push YOUR_USERNAME/minecraft-server:1.0.0
```

### Using Your Published Image

Update `docker-compose.yml`:
```yaml
services:
  minecraft:
    image: YOUR_USERNAME/minecraft-server:latest  # Instead of 'build: .'
    # ... rest of configuration
```

---

## GitHub Container Registry

### Prerequisites
1. Create a Personal Access Token (PAT) at https://github.com/settings/tokens
   - Required scopes: `write:packages`, `read:packages`, `delete:packages`
2. Save your token securely

### Login to GitHub Container Registry

```bash
# Using your GitHub username and PAT
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

### Building and Pushing

```bash
# Build the image
docker build -t ghcr.io/YOUR_GITHUB_USERNAME/minecraft-server:latest .

# Tag with version
docker tag ghcr.io/YOUR_GITHUB_USERNAME/minecraft-server:latest \
  ghcr.io/YOUR_GITHUB_USERNAME/minecraft-server:1.0.0

# Push to GitHub Container Registry
docker push ghcr.io/YOUR_GITHUB_USERNAME/minecraft-server:latest
docker push ghcr.io/YOUR_GITHUB_USERNAME/minecraft-server:1.0.0
```

### Multi-platform Build (ARM64 + AMD64)

```bash
# Create and use buildx builder
docker buildx create --name multiplatform --use
docker buildx inspect --bootstrap

# Build and push for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/YOUR_GITHUB_USERNAME/minecraft-server:latest \
  --push .
```

### Make Package Public (Optional)

1. Go to https://github.com/YOUR_USERNAME?tab=packages
2. Click on your `minecraft-server` package
3. Click "Package settings"
4. Scroll to "Danger Zone" → "Change visibility" → Make Public

### Using Your Published Image

Update `docker-compose.yml`:
```yaml
services:
  minecraft:
    image: ghcr.io/YOUR_GITHUB_USERNAME/minecraft-server:latest
    # ... rest of configuration
```

---

## Quick Commands

### Using the Helper Script

```bash
# Build the image locally
./build.sh

# Build and push to Docker Hub
./build.sh --push dockerhub YOUR_USERNAME

# Build and push to GitHub Container Registry
./build.sh --push ghcr YOUR_GITHUB_USERNAME

# Build multi-platform and push
./build.sh --push ghcr YOUR_GITHUB_USERNAME --multiplatform
```

### Manual Commands

```bash
# Build locally
docker build -t minecraft-server:latest .

# Test locally before pushing
docker-compose up -d

# Login to Docker Hub
docker login

# Login to GitHub Container Registry
echo YOUR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Tag and push (Docker Hub)
docker tag minecraft-server:latest YOUR_USERNAME/minecraft-server:latest
docker push YOUR_USERNAME/minecraft-server:latest

# Tag and push (GitHub)
docker tag minecraft-server:latest ghcr.io/YOUR_USERNAME/minecraft-server:latest
docker push ghcr.io/YOUR_USERNAME/minecraft-server:latest
```

---

## GitHub Actions (CI/CD)

For automated builds on every commit, add `.github/workflows/docker-publish.yml`:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## Best Practices

### Version Tagging

```bash
# Always tag with semantic versioning
docker tag image:latest image:1.0.0

# Tag with Minecraft version
docker tag image:latest image:mc-1.21

# Tag with date
docker tag image:latest image:$(date +%Y%m%d)
```

### Multi-platform Support

Build for both AMD64 and ARM64 to support different architectures:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t YOUR_REGISTRY/minecraft-server:latest \
  --push .
```

### Testing Before Publishing

```bash
# Build locally
docker build -t minecraft-server:test .

# Test with docker-compose
docker run -p 25565:25565 -e EULA=TRUE minecraft-server:test

# If successful, tag and push
docker tag minecraft-server:test YOUR_USERNAME/minecraft-server:latest
docker push YOUR_USERNAME/minecraft-server:latest
```

---

## Troubleshooting

### "denied: requested access to the resource is denied"
- Ensure you're logged in: `docker login` or `docker login ghcr.io`
- Check your username/token is correct
- For GitHub: Ensure your token has `write:packages` scope

### Multi-platform builds not working
```bash
# Install and setup buildx
docker buildx create --name multiplatform --use
docker buildx inspect --bootstrap
```

### Image size too large
```bash
# View image size
docker images | grep minecraft-server

# Use .dockerignore to exclude unnecessary files
# Clean up layers in Dockerfile
```

---

## Additional Resources

- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
