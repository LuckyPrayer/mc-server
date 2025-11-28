# Minecraft Server Docker Setup

A Docker-based Minecraft server setup with easy management of datapacks, plugins, and resource packs.

## Features

- 🐳 Docker containerized Minecraft server
- 📦 Easy datapack, plugin, and resource pack management
- 🔄 Automatic copying of custom content to server
- 💾 Persistent world data storage
- ⚙️ Configurable server settings via docker-compose
- 🚀 Simple start/stop/restart commands

## Prerequisites

- Docker
- Docker Compose

## Directory Structure

```
mc-server/
├── docker-compose.yml          # Base configuration file
├── docker-compose.dev.yml      # Development configuration
├── docker-compose.prod.yml     # Production configuration
├── Dockerfile                  # Base Docker image
├── Dockerfile.dev              # Development Docker image
├── Dockerfile.prod             # Production Docker image
├── build.sh                    # Build and push helper script
├── manage.sh                   # Server management script
├── datapacks/                  # Place your datapacks here (.zip files)
├── plugins/                    # Place your plugins here (.jar files)
├── resourcepacks/              # Place your resource packs here (.zip files)
├── config/                     # Additional config files
├── data-dev/                   # Development server data (generated)
├── data-prod/                  # Production server data (generated)
├── logs-dev/                   # Development server logs (generated)
└── logs-prod/                  # Production server logs (generated)
```

## Quick Start

### 1. Choose Your Environment

This project supports two environments:
- **Development** (`docker-compose.dev.yml`): Lower resources, creative mode, offline mode, debug logging
- **Production** (`docker-compose.prod.yml`): High performance, survival mode, online mode, optimized

### 2. Configure Your Server

**For Development:**
Edit `docker-compose.dev.yml` to customize settings:

```yaml
environment:
  TYPE: "PAPER"
  VERSION: "LATEST"
  MEMORY: "1G"
  MAX_MEMORY: "2G"
  MODE: "creative"
  DIFFICULTY: "peaceful"
  ONLINE_MODE: "false"
```

**For Production:**
Edit `docker-compose.prod.yml` to customize settings:

```yaml
environment:
  TYPE: "PAPER"              # Server type (VANILLA, PAPER, SPIGOT, FORGE, FABRIC, etc.)
  VERSION: "LATEST"          # Minecraft version
  MEMORY: "2G"               # Initial memory
  MAX_MEMORY: "4G"           # Maximum memory
  SERVER_NAME: "My Server"   # Server name
  DIFFICULTY: "normal"       # easy, normal, hard
  MODE: "survival"           # survival, creative, adventure
  MAX_PLAYERS: "20"          # Maximum players
  # ... more settings available
```

### 3. Add Your Content

- **Datapacks**: Copy `.zip` datapack files to `datapacks/`
- **Plugins**: Copy `.jar` plugin files to `plugins/` (Paper/Spigot only)
- **Resource Packs**: Copy `.zip` resource pack files to `resourcepacks/`
- **Config Files**: Add ops.json, whitelist.json, etc. to `config/`

### 4. Start the Server

**Development:**
```bash
# Build and start development server
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop the server
docker-compose -f docker-compose.dev.yml down
```

**Production:**
```bash
# Build and start production server
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop the server
docker-compose -f docker-compose.prod.yml down
```

## Common Commands

```bash
# Start the server
docker-compose up -d

# Stop the server
docker-compose down

# Restart the server
docker-compose restart

# View real-time logs
docker-compose logs -f minecraft

# Execute commands in the server console
docker exec -i minecraft-server rcon-cli

# Backup the world
docker-compose exec minecraft rcon-cli save-all
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz data/

# Update server
docker-compose down
docker-compose pull
docker-compose up -d
```

## Server Console Access

To access the Minecraft server console:

```bash
# Using RCON (if enabled)
docker exec -i minecraft-server rcon-cli

# Or attach to the container
docker attach minecraft-server
# Press Ctrl+P, Ctrl+Q to detach without stopping
```

## Server Types

The `TYPE` environment variable supports:

- `VANILLA` - Official Minecraft server
- `PAPER` - High-performance fork with plugin support (recommended)
- `SPIGOT` - Plugin-compatible server
- `FORGE` - Mod support
- `FABRIC` - Lightweight mod support
- `PURPUR` - Fork of Paper with additional features
- `BUKKIT` - Classic plugin server

**Note**: Plugins only work with Paper, Spigot, Bukkit, and Purpur.

## Environment Variables

Key environment variables you can customize in `docker-compose.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `EULA` | `TRUE` | Accept Minecraft EULA |
| `TYPE` | `PAPER` | Server type |
| `VERSION` | `LATEST` | Minecraft version |
| `MEMORY` | `2G` | Initial heap size |
| `MAX_MEMORY` | `4G` | Maximum heap size |
| `SERVER_NAME` | `Minecraft Server` | Server name |
| `MOTD` | `Welcome!` | Message of the day |
| `DIFFICULTY` | `normal` | Game difficulty |
| `MODE` | `survival` | Game mode |
| `MAX_PLAYERS` | `20` | Maximum players |
| `ONLINE_MODE` | `true` | Authenticate with Mojang |
| `PVP` | `true` | Enable PvP |
| `VIEW_DISTANCE` | `10` | View distance in chunks |
| `ENABLE_RCON` | `true` | Enable remote console |
| `RCON_PASSWORD` | `minecraft` | RCON password |

## Port Configuration

Default ports:
- `25565` - Minecraft server (TCP)
- `25575` - RCON (TCP)

To change the Minecraft port:

```yaml
ports:
  - "25566:25565"  # External:Internal
```

## Persistent Data

Server data is stored in the `data/` directory, which is mounted as a volume. This includes:
- World files
- Player data
- Server configurations
- Installed plugins/mods

## Troubleshooting

### Server won't start
- Check logs: `docker-compose logs minecraft`
- Ensure ports aren't in use: `lsof -i :25565`
- Verify EULA is accepted in docker-compose.yml

### Plugins not loading
- Ensure you're using PAPER, SPIGOT, or BUKKIT server type
- Check plugin compatibility with your Minecraft version
- View logs for plugin errors

### Out of memory
- Increase `MAX_MEMORY` in docker-compose.yml
- Reduce `VIEW_DISTANCE` or `MAX_PLAYERS`

## Advanced Configuration

### Custom server.properties

The server will generate `data/server.properties`. You can mount a custom one:

```yaml
volumes:
  - ./server.properties:/data/server.properties
```

### World Seed

Set a custom world seed:

```yaml
environment:
  SEED: "your-seed-here"
```

### Whitelist

1. Create `config/whitelist.json`:
```json
[
  {
    "uuid": "player-uuid",
    "name": "PlayerName"
  }
]
```

2. Enable whitelist:
```yaml
environment:
  WHITELIST: "true"
```

## Backing Up Your Server

```bash
# Stop the server gracefully
docker-compose exec minecraft rcon-cli save-all
docker-compose exec minecraft rcon-cli save-off

# Create backup
tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz data/

# Resume saving
docker-compose exec minecraft rcon-cli save-on
```

## Building and Publishing

### Development and Production Builds

This project supports separate development and production environments with different configurations:

**Development Environment:**
```bash
# Build for development
./build.sh --env dev

# Push to Harbor dev registry
./build.sh --env dev --push harbor
```

**Production Environment:**
```bash
# Build for production
./build.sh --env prod

# Push to Harbor prod registry
./build.sh --env prod --push harbor --version 1.0.0
```

See [HARBOR_SETUP.md](HARBOR_SETUP.md) for complete Harbor registry setup and usage instructions.

### Alternative Registries

Want to publish to Docker Hub or GitHub Container Registry? See [DOCKER_PUBLISHING.md](DOCKER_PUBLISHING.md) for detailed instructions on:
- Building and pushing to Docker Hub
- Publishing to GitHub Container Registry
- Multi-platform builds (ARM64 + AMD64)
- CI/CD with GitHub Actions

Quick start:
```bash
# Build and push to Docker Hub
./build.sh --env prod --push dockerhub --username YOUR_USERNAME

# Build and push to GitHub Container Registry
./build.sh --env prod --push ghcr --username YOUR_GITHUB_USERNAME
```

## Resources

- [itzg/minecraft-server Documentation](https://github.com/itzg/docker-minecraft-server)
- [Minecraft Server Properties](https://minecraft.fandom.com/wiki/Server.properties)
- [Paper Documentation](https://docs.papermc.io/)

## License

This setup is provided as-is. Minecraft is © Mojang Studios.
