# Configuration Templates - Quick Reference

## 🚀 Quick Start

```bash
# 1. Set up environment
cp .env.example .env
cp .env.dev.example .env.dev
cp .env.prod.example .env.prod

# 2. Edit your environment files
nano .env.prod  # Set RCON_PASSWORD and other values

# 3. Start server (templates auto-process)
docker-compose -f docker-compose.dev.yml up -d
```

## 📁 What Gets Generated

Templates → Generated Configs:
```
/templates/server/*.template     →  /data/*.yml or .properties
/templates/plugins/*/*.template  →  /data/plugins/*/*.yml or .conf
```

## 🔧 Local Commands

```bash
# Generate configs locally
./generate-configs.sh dev              # Development
./generate-configs.sh prod             # Production
./generate-configs.sh dev --dry-run    # Preview only

# Using management script
./manage.sh generate-configs           # Interactive

# Specific plugin only
./generate-configs.sh prod --plugin BlueMap

# Force overwrite
./generate-configs.sh prod --force
```

## 🐳 Runtime Behavior

Containers automatically:
1. Load environment variables
2. Process templates from `/templates/`
3. Generate configs in `/data/` and `/data/plugins/`
4. Start Minecraft server

View logs:
```bash
docker logs minecraft-server-dev
```

## 📝 Template Syntax

```properties
# Basic substitution
server-name=${SERVER_NAME}

# With default value
max-players=${MAX_PLAYERS:-20}

# Required variable (fails if not set)
rcon-password=${RCON_PASSWORD:?Password required}
```

## 🌍 Environment Variables

### Essential Variables
```bash
# Server identity
SERVER_NAME=My Server
MOTD=Welcome!

# Security
RCON_PASSWORD=<required-for-prod>

# Gameplay
GAMEMODE=survival
DIFFICULTY=normal
MAX_PLAYERS=20
```

### Plugin Variables
```bash
# BlueMap
BLUEMAP_ACCEPT_DOWNLOAD=true
BLUEMAP_PORT=8100

# DiscordSRV
DISCORD_BOT_TOKEN=<your-token>
DISCORD_GUILD_ID=<your-guild-id>
DISCORD_CHAT_CHANNEL_ID=<your-channel-id>

# Geyser
GEYSER_PORT=19132
GEYSER_AUTH_TYPE=floodgate
```

## 📂 File Structure

```
mc-server/
├── .env                         # Base config (not committed)
├── .env.dev                     # Dev overrides (not committed)
├── .env.prod                    # Prod overrides (not committed)
├── .env.example                 # Template (committed)
├── .env.dev.example             # Dev template (committed)
├── .env.prod.example            # Prod template (committed)
├── templates/                   # Templates (committed)
│   ├── server/                  # Server configs
│   └── plugins/                 # Plugin configs
├── config/                      # Generated server configs (not committed)
├── docs/                        # Documentation (committed)
├── generate-configs.sh          # Local generator
└── scripts/entrypoint.sh        # Container processor
```

## 🔍 Debugging

```bash
# Check environment in container
docker exec minecraft-server-dev printenv | grep SERVER

# View generated config
docker exec minecraft-server-dev cat /data/server.properties

# Check templates exist
docker exec minecraft-server-dev ls -la /templates/

# Find unsubstituted variables
grep '\${' config/*

# Test locally first
./generate-configs.sh dev
cat config/server.properties
```

## ✅ Verification Checklist

Before deploying:
- [ ] Copied .env.example to .env.prod
- [ ] Set RCON_PASSWORD (required!)
- [ ] Set plugin tokens if using (Discord, etc.)
- [ ] Tested locally: `./generate-configs.sh prod --dry-run`
- [ ] Reviewed generated configs
- [ ] Built image: `./build.sh --env prod`
- [ ] Tested in dev first

## 🆘 Common Issues

**Templates not processing?**
```bash
# Check entrypoint exists
docker exec <container> ls -la /entrypoint.sh

# Check templates exist
docker exec <container> ls -la /templates/
```

**Variable not substituted?**
```bash
# Verify it's set
docker exec <container> printenv | grep VAR_NAME

# Check docker-compose has env_file
grep env_file docker-compose*.yml
```

**Config malformed?**
```bash
# Test locally first
./generate-configs.sh dev
cat config/server.properties | less
```

## 📚 Full Documentation

- **Complete Guide:** [TEMPLATING_GUIDE.md](TEMPLATING_GUIDE.md)
- **Implementation:** [TEMPLATE_IMPLEMENTATION.md](TEMPLATE_IMPLEMENTATION.md)
- **Templates Info:** [templates/README.md](templates/README.md)

## 🔐 Security Reminders

- ❌ Never commit `.env` files
- ✅ Always use `.env.example` as template
- ✅ Generate strong passwords: `openssl rand -base64 32`
- ✅ Review generated configs before deploying
- ✅ Use `${VAR:?required}` for sensitive values

## 💡 Pro Tips

1. **Test locally** before deploying to container
2. **Use defaults** for optional settings: `${VAR:-default}`
3. **Document variables** in `.env.example`
4. **Keep env files simple** - one value per line
5. **Use env-specific files** - `.env.dev` vs `.env.prod`
6. **Version control templates** - track config changes
7. **Monitor first start** - watch template processing logs

---

**Need Help?** See [TEMPLATING_GUIDE.md](TEMPLATING_GUIDE.md) for detailed documentation.
