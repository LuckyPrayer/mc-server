FROM itzg/minecraft-server:latest

# Set environment variables with default values
ENV EULA=TRUE \
    TYPE=PAPER \
    VERSION=LATEST \
    MEMORY=2G \
    MAX_MEMORY=4G \
    SERVER_NAME="Minecraft Server" \
    DIFFICULTY=normal \
    MODE=survival \
    ALLOW_NETHER=true \
    ENABLE_COMMAND_BLOCK=true \
    MAX_PLAYERS=20 \
    ONLINE_MODE=true \
    PVP=true \
    VIEW_DISTANCE=10

# Copy datapacks, plugins, and resourcepacks from local directories
COPY --chown=minecraft:minecraft datapacks/ /datapacks/
COPY --chown=minecraft:minecraft plugins/ /plugins/
COPY --chown=minecraft:minecraft resourcepacks/ /resourcepacks/

# Copy server configuration if it exists
COPY --chown=minecraft:minecraft config/ /config/

# Copy templates for runtime configuration generation
COPY --chown=minecraft:minecraft templates/ /templates/

# Copy default environment variable files
COPY --chown=minecraft:minecraft defaults/ /defaults/

# Copy entrypoint script for template processing
COPY --chown=minecraft:minecraft scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose Minecraft server port
EXPOSE 25565

# Use custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]
