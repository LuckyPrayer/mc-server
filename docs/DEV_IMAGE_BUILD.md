# Development Image Build Complete! 🎉

**Date:** November 29, 2025  
**Image:** `minecraft-server:dev-latest`  
**Size:** 889MB  
**Environment:** Development

---

## ✅ Build Summary

The development Docker image has been successfully built with:

- **Base Image:** `itzg/minecraft-server:latest`
- **Server Type:** Spigot 1.21.5
- **Environment:** Development configuration
- **Templates:** All plugin templates included (72KB)
- **Entrypoint:** Custom template processor (`/entrypoint.sh`)

---

## 📦 What's Included

### Server Configuration Templates (5 files)
- `server.properties.template`
- `bukkit.yml.template`
- `spigot.yml.template`
- `paper-global.yml.template`
- `paper-world-defaults.yml.template`

### Plugin Configuration Templates (4 plugins)
- **BlueMap** - 3 templates (core, webserver, webapp)
- **DiscordSRV** - 1 template (config.yml)
- **Geyser-Spigot** - 1 template (config.yml)
- **Floodgate** - 1 template (config.yml)

### Scripts
- `/entrypoint.sh` - Template processor (runs before Minecraft starts)
- `/tmp/add-server-icon.sh` - Server icon setup

### Content Directories
- `/datapacks/` - Minecraft datapacks
- `/plugins/` - Plugin JARs (77.9MB included)
- `/resourcepacks/` - Resource packs
- `/config/` - Server config files

---

## 🚀 Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
# Make sure you have a .env file
cp .env.dev.example .env.dev

# Edit and set required variables
nano .env.dev

# Start the server
docker-compose -f docker-compose.dev.yml up -d

# Check logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop the server
docker-compose -f docker-compose.dev.yml down
```

### Option 2: Using Docker Run

```bash
# Basic run with EULA acceptance
docker run -d \
  --name minecraft-dev \
  -p 25565:25565 \
  -p 25575:25575 \
  -p 8100:8100 \
  -p 19132:19132/udp \
  -e EULA=TRUE \
  -e TYPE=SPIGOT \
  -e VERSION=1.21.5 \
  -e BLUEMAP_ACCEPT_DOWNLOAD=true \
  -v minecraft-data:/data \
  minecraft-server:dev-latest

# With environment file
docker run -d \
  --name minecraft-dev \
  -p 25565:25565 \
  -p 25575:25575 \
  -p 8100:8100 \
  -p 19132:19132/udp \
  --env-file .env.dev \
  -e EULA=TRUE \
  -v minecraft-data:/data \
  minecraft-server:dev-latest
```

---

## 🔧 Configuration

### Required Environment Variables

```bash
# Minimum required
EULA=TRUE

# BlueMap (if using BlueMap plugin)
BLUEMAP_ACCEPT_DOWNLOAD=true

# DiscordSRV (if using DiscordSRV plugin)
DISCORD_BOT_TOKEN=your_bot_token_here
DISCORD_CHAT_CHANNEL_ID=your_channel_id_here
```

### Recommended Development Settings

```bash
# Server identity
SERVER_NAME=[DEV] My Server
MOTD=§e[DEVELOPMENT] §fWelcome!

# Development-friendly settings
GAMEMODE=creative
DIFFICULTY=peaceful
ONLINE_MODE=false
MAX_PLAYERS=10
ALLOW_FLIGHT=true
DEBUG=true

# Performance
MEMORY=2G
MAX_MEMORY=4G
VIEW_DISTANCE=8

# Geyser Bedrock support
GEYSER_PORT=19132
GEYSER_AUTH_TYPE=floodgate
GEYSER_DEBUG=true

# BlueMap
BLUEMAP_PORT=8100
BLUEMAP_RENDER_THREADS=2
```

---

## 📊 Exposed Ports

| Port | Protocol | Service |
|------|----------|---------|
| 25565 | TCP | Minecraft Java Edition |
| 25575 | TCP | RCON (Remote Console) |
| 8100 | TCP | BlueMap Web Interface |
| 19132 | UDP | Geyser (Bedrock Edition) |

---

## 🔍 Verifying the Build

### Check Image Details
```bash
# List images
docker images | grep minecraft-server

# Inspect the image
docker inspect minecraft-server:dev-latest

# Check size
docker image inspect minecraft-server:dev-latest --format='{{.Size}}' | numfmt --to=iec-i

# Check labels
docker image inspect minecraft-server:dev-latest --format='{{json .Config.Labels}}' | jq .
```

### Verify Templates are Included
```bash
# Check entrypoint
docker inspect minecraft-server:dev-latest --format='{{.Config.Entrypoint}}'

# List templates (will show entrypoint output)
docker run --rm minecraft-server:dev-latest ls -la /templates/

# Test config generation (dry run)
docker run --rm \
  -e BLUEMAP_ACCEPT_DOWNLOAD=true \
  -e SERVER_NAME=TestServer \
  minecraft-server:dev-latest \
  cat /data/server.properties
```

---

## 🐛 Troubleshooting

### Templates Not Processing
```bash
# Check if entrypoint is set
docker inspect minecraft-server:dev-latest --format='{{.Config.Entrypoint}}'
# Should show: [/entrypoint.sh]

# Check entrypoint exists
docker run --rm minecraft-server:dev-latest ls -la /entrypoint.sh
```

### Server Not Starting
```bash
# Check logs
docker logs minecraft-dev

# Interactive shell for debugging
docker run -it --rm \
  -e EULA=TRUE \
  minecraft-server:dev-latest \
  /bin/bash

# Inside container, check:
ls -la /templates/
ls -la /entrypoint.sh
cat /entrypoint.sh
```

### Port Conflicts
```bash
# Check what's using ports
sudo netstat -tulpn | grep -E '25565|25575|8100|19132'

# Use different ports
docker run -d \
  -p 25566:25565 \
  -p 25576:25575 \
  -p 8101:8100 \
  minecraft-server:dev-latest
```

### Permission Issues
```bash
# Check data directory permissions
ls -la minecraft-data/

# Fix permissions (if needed)
sudo chown -R 1000:1000 minecraft-data/
```

---

## 📝 Next Steps

### 1. Configure Environment Variables
```bash
# Create .env file from example
cp .env.dev.example .env.dev

# Edit with your settings
nano .env.dev

# At minimum, set:
BLUEMAP_ACCEPT_DOWNLOAD=true
DISCORD_BOT_TOKEN=your_token  # If using DiscordSRV
```

### 2. Start the Server
```bash
# Using docker-compose (recommended)
docker-compose -f docker-compose.dev.yml up -d

# Or using docker run
docker run -d --name minecraft-dev \
  --env-file .env.dev \
  -e EULA=TRUE \
  -p 25565:25565 \
  -p 8100:8100 \
  -v minecraft-data:/data \
  minecraft-server:dev-latest
```

### 3. Monitor Startup
```bash
# Watch logs
docker logs -f minecraft-dev

# You should see:
# - Template processor output
# - Configuration generation
# - Minecraft server startup
```

### 4. Connect and Test
```bash
# Minecraft Java: localhost:25565
# BlueMap: http://localhost:8100
# RCON: localhost:25575

# Test RCON
docker exec minecraft-dev rcon-cli
```

### 5. Verify Generated Configs
```bash
# Check server properties
docker exec minecraft-dev cat /data/server.properties

# Check plugin configs
docker exec minecraft-dev ls -la /data/plugins/
docker exec minecraft-dev cat /data/plugins/BlueMap/core.conf
docker exec minecraft-dev cat /data/plugins/DiscordSRV/config.yml
```

---

## 🔄 Rebuilding

### When to Rebuild
- After updating templates
- After modifying entrypoint.sh
- After adding new plugins
- After changing Dockerfile.dev

### How to Rebuild
```bash
# Stop running containers
docker-compose -f docker-compose.dev.yml down

# Rebuild the image
./build.sh --env dev

# Or with docker-compose
docker-compose -f docker-compose.dev.yml build --no-cache

# Start with new image
docker-compose -f docker-compose.dev.yml up -d
```

---

## 📚 Documentation References

- **Build Script:** `./build.sh --help`
- **Docker Compose:** `docker-compose.dev.yml`
- **Dockerfile:** `Dockerfile.dev`
- **Templates:** `templates/`
- **Environment:** `.env.dev.example`
- **Templating Guide:** `docs/TEMPLATING_GUIDE.md`
- **Plugin Migration:** `docs/PLUGIN_MIGRATION_1.21.5.md`

---

## ✨ Features

✅ **Automatic Template Processing** - Configs generated at startup  
✅ **Environment Variable Support** - 222+ configurable variables  
✅ **Plugin Ready** - BlueMap, DiscordSRV, Geyser, Floodgate  
✅ **Spigot 1.21.5 Compatible** - Latest version support  
✅ **Development Optimized** - Debug enabled, creative mode defaults  
✅ **Multi-Platform Ready** - Can build for amd64/arm64  

---

## 🎯 Image Labels

```json
{
  "environment": "development",
  "maintainer": "dev-team",
  "description": "Spigot 1.21.5 - Development Build"
}
```

---

**Build Status:** ✅ **Success**  
**Ready to Deploy:** 🚀 **Yes**  
**Image Tag:** `minecraft-server:dev-latest`

---

**Built on:** November 29, 2025  
**Build Time:** ~6.5 seconds  
**Layers:** 16 (11 custom + 5 base)
