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
# These will be synced to the appropriate server directories
COPY --chown=minecraft:minecraft datapacks/ /datapacks/
COPY --chown=minecraft:minecraft plugins/ /plugins/
COPY --chown=minecraft:minecraft resourcepacks/ /resourcepacks/

# Copy server configuration if it exists
COPY --chown=minecraft:minecraft config/ /config/

# Copy templates for runtime configuration generation (optional)
COPY --chown=minecraft:minecraft templates/ /templates/ 2>/dev/null || true

# Copy default environment variable files (optional)
COPY --chown=minecraft:minecraft defaults/ /defaults/ 2>/dev/null || true

# Copy entrypoint script for template processing (optional)
COPY --chown=minecraft:minecraft scripts/entrypoint.sh /entrypoint.sh 2>/dev/null || true
RUN if [ -f /entrypoint.sh ]; then chmod +x /entrypoint.sh; fi

# Expose Minecraft server port
EXPOSE 25565

# Use custom entrypoint if available, otherwise use default
ENTRYPOINT ["/bin/sh", "-c", "if [ -f /entrypoint.sh ]; then /entrypoint.sh; else /start; fi"]
