# Plugin Configurations

This directory is for custom plugin configuration files for:
- BlueMap
- DiscordSRV
- Geyser
- Floodgate

Place your configuration files in subfolders named after each plugin, for example:
- `plugin-configs/BlueMap/`
- `plugin-configs/DiscordSRV/`
- `plugin-configs/Geyser/`
- `plugin-configs/Floodgate/`

These will be mounted into `/data/plugins/` in the server container, making them available to Spigot plugins.
