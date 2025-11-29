# Generated Configurations

This directory contains **generated** configuration files created by the template system.

## ⚠️ Do Not Edit These Files Directly

Configuration files in this directory are automatically generated from templates at build time or runtime. Any manual changes will be overwritten.

## How to Modify Configurations

1. **Edit templates**: Modify files in `templates/server/` directory
2. **Set environment variables**: Update `.env`, `.env.dev`, or `.env.prod` files
3. **Regenerate configs**: Run `./generate-configs.sh [dev|prod]` or rebuild containers

## What Gets Generated

When you run the configuration generator or start a container, the following files are created here:

- `server.properties` - Main server configuration
- `bukkit.yml` - Bukkit server settings
- `spigot.yml` - Spigot server settings  
- `paper-global.yml` - Paper global configuration
- `paper-world-defaults.yml` - Paper world defaults

## Version Control

These generated files are **not tracked** by Git (see `.gitignore`). Only the templates in `templates/` are version controlled.

## See Also

- [Templating Guide](../docs/TEMPLATING_GUIDE.md) - Complete templating documentation
- [Quick Reference](../docs/TEMPLATES_QUICKREF.md) - Cheat sheet for templates
- [templates/](../templates/) - Template source files
