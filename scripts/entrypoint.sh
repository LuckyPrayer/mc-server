#!/bin/bash
# Container entrypoint script
# Processes configuration templates before starting the Minecraft server

set -e

echo "======================================"
echo "Minecraft Server - Template Processor"
echo "======================================"
echo ""

# Configuration paths
ENV_SNAPSHOT_FILE="/data/.env_snapshot"
TEMP_DIR="/tmp/minecraft-configs"

# Set default values for environment variables
# This allows templates to use simple ${VAR} syntax instead of ${VAR:-default}
echo "Setting default values for environment variables..."

# DiscordSRV defaults
export DISCORD_CONSOLE_CHANNEL_ID="${DISCORD_CONSOLE_CHANNEL_ID:-}"
export DISCORD_JDBC_URL="${DISCORD_JDBC_URL:-jdbc:mysql://HOST:PORT/DATABASE?autoReconnect=true&useSSL=false}"
export DISCORD_JDBC_PREFIX="${DISCORD_JDBC_PREFIX:-discordsrv}"
export DISCORD_JDBC_USERNAME="${DISCORD_JDBC_USERNAME:-username}"
export DISCORD_JDBC_PASSWORD="${DISCORD_JDBC_PASSWORD:-password}"
export DISCORD_WEBHOOK_DELIVERY="${DISCORD_WEBHOOK_DELIVERY:-false}"
export DISCORD_WEBHOOK_USERNAME_FORMAT="${DISCORD_WEBHOOK_USERNAME_FORMAT:-%displayname%}"
export DISCORD_WEBHOOK_MESSAGE_FORMAT="${DISCORD_WEBHOOK_MESSAGE_FORMAT:-%message%}"
export DISCORD_WEBHOOK_USERNAME_FROM_DISCORD="${DISCORD_WEBHOOK_USERNAME_FROM_DISCORD:-false}"
export DISCORD_WEBHOOK_AVATAR_FROM_DISCORD="${DISCORD_WEBHOOK_AVATAR_FROM_DISCORD:-false}"
export DISCORD_AVATAR_URL="${DISCORD_AVATAR_URL:-}"
export DISCORD_RESERIALIZER_TO_DISCORD="${DISCORD_RESERIALIZER_TO_DISCORD:-false}"
export DISCORD_RESERIALIZER_TO_MINECRAFT="${DISCORD_RESERIALIZER_TO_MINECRAFT:-false}"
export DISCORD_RESERIALIZER_IN_BROADCAST="${DISCORD_RESERIALIZER_IN_BROADCAST:-false}"
export DISCORD_CANCEL_CONSOLE_IF_LOGGING_FAILED="${DISCORD_CANCEL_CONSOLE_IF_LOGGING_FAILED:-true}"
export DISCORD_FORCED_LANGUAGE="${DISCORD_FORCED_LANGUAGE:-none}"
export DISCORD_FORCE_TLS="${DISCORD_FORCE_TLS:-true}"
export DISCORD_NOOP_HOSTNAME_VERIFIER="${DISCORD_NOOP_HOSTNAME_VERIFIER:-false}"
export DISCORD_MAX_DNS_ATTEMPTS="${DISCORD_MAX_DNS_ATTEMPTS:-3}"
export DISCORD_TIMESTAMP_FORMAT="${DISCORD_TIMESTAMP_FORMAT:-EEE, d. MMM yyyy HH:mm:ss z}"
export DISCORD_DATE_FORMAT="${DISCORD_DATE_FORMAT:-yyyy-MM-dd}"
export DISCORD_TIMEZONE="${DISCORD_TIMEZONE:-default}"
export DISCORD_MINECRAFT_MENTION_SOUND="${DISCORD_MINECRAFT_MENTION_SOUND:-true}"
export DISCORD_VENTURECHAT_BUNGEE="${DISCORD_VENTURECHAT_BUNGEE:-false}"
export DISCORD_ENABLE_PRESENCE="${DISCORD_ENABLE_PRESENCE:-false}"
export DISCORD_USE_MODERN_PAPER_CHAT="${DISCORD_USE_MODERN_PAPER_CHAT:-false}"
export DISCORD_GAME_STATUS="${DISCORD_GAME_STATUS:-Minecraft}"
export DISCORD_ONLINE_STATUS="${DISCORD_ONLINE_STATUS:-ONLINE}"
export DISCORD_STATUS_UPDATE_RATE="${DISCORD_STATUS_UPDATE_RATE:-2}"
export DISCORD_CHAT_DISCORD_TO_MC="${DISCORD_CHAT_DISCORD_TO_MC:-true}"
export DISCORD_CHAT_MC_TO_DISCORD="${DISCORD_CHAT_MC_TO_DISCORD:-true}"
export DISCORD_CHAT_TRUNCATE_LENGTH="${DISCORD_CHAT_TRUNCATE_LENGTH:-256}"
export DISCORD_CHAT_TRANSLATE_MENTIONS="${DISCORD_CHAT_TRANSLATE_MENTIONS:-true}"
export DISCORD_CHAT_EMOJI_BEHAVIOR="${DISCORD_CHAT_EMOJI_BEHAVIOR:-name}"
export DISCORD_CHAT_EMOTE_BEHAVIOR="${DISCORD_CHAT_EMOTE_BEHAVIOR:-name}"
export DISCORD_CHAT_PREFIX="${DISCORD_CHAT_PREFIX:-}"
export DISCORD_CHAT_PREFIX_BLACKLIST="${DISCORD_CHAT_PREFIX_BLACKLIST:-false}"
export DISCORD_CHAT_COLOR_ROLES="${DISCORD_CHAT_COLOR_ROLES:-Admin}"
export DISCORD_CHAT_BROADCAST_TO_CONSOLE="${DISCORD_CHAT_BROADCAST_TO_CONSOLE:-true}"
export DISCORD_CHAT_REQUIRE_LINKED="${DISCORD_CHAT_REQUIRE_LINKED:-false}"
export DISCORD_CHAT_BLOCK_BOTS="${DISCORD_CHAT_BLOCK_BOTS:-true}"
export DISCORD_CHAT_BLOCK_WEBHOOKS="${DISCORD_CHAT_BLOCK_WEBHOOKS:-true}"
export DISCORD_CHAT_BLOCKED_ROLES_AS_WHITELIST="${DISCORD_CHAT_BLOCKED_ROLES_AS_WHITELIST:-false}"
export DISCORD_CHAT_ROLES_AS_WHITELIST="${DISCORD_CHAT_ROLES_AS_WHITELIST:-false}"
export DISCORD_INVITE_LINK="${DISCORD_INVITE_LINK:-Join our Discord!}"
export DISCORD_CONSOLE_REFRESH_RATE="${DISCORD_CONSOLE_REFRESH_RATE:-5}"
export DISCORD_CONSOLE_LOG_FILE="${DISCORD_CONSOLE_LOG_FILE:-Console-%date%.log}"
export DISCORD_CONSOLE_BLACKLIST_AS_WHITELIST="${DISCORD_CONSOLE_BLACKLIST_AS_WHITELIST:-false}"
export DISCORD_CONSOLE_USE_CODE_BLOCKS="${DISCORD_CONSOLE_USE_CODE_BLOCKS:-true}"
export DISCORD_CONSOLE_BLOCK_BOTS="${DISCORD_CONSOLE_BLOCK_BOTS:-false}"
export DISCORD_CHAT_CONSOLE_COMMANDS_ENABLED="${DISCORD_CHAT_CONSOLE_COMMANDS_ENABLED:-false}"
export DISCORD_CHAT_CONSOLE_NOTIFY_ERRORS="${DISCORD_CHAT_CONSOLE_NOTIFY_ERRORS:-true}"
export DISCORD_CHAT_CONSOLE_PREFIX="${DISCORD_CHAT_CONSOLE_PREFIX:-!c}"
export DISCORD_CHAT_CONSOLE_ROLES="${DISCORD_CHAT_CONSOLE_ROLES:-Admin}"
export DISCORD_CHAT_CONSOLE_BYPASS_ROLES="${DISCORD_CHAT_CONSOLE_BYPASS_ROLES:-Owner}"
export DISCORD_CHAT_CONSOLE_WHITELIST_AS_BLACKLIST="${DISCORD_CHAT_CONSOLE_WHITELIST_AS_BLACKLIST:-false}"
export DISCORD_CHAT_CONSOLE_EXPIRATION="${DISCORD_CHAT_CONSOLE_EXPIRATION:-0}"
export DISCORD_CHAT_CONSOLE_DELETE_REQUEST="${DISCORD_CHAT_CONSOLE_DELETE_REQUEST:-true}"
export DISCORD_LIST_COMMAND_ENABLED="${DISCORD_LIST_COMMAND_ENABLED:-true}"
export DISCORD_LIST_COMMAND_MESSAGE="${DISCORD_LIST_COMMAND_MESSAGE:-playerlist}"
export DISCORD_LIST_COMMAND_EXPIRATION="${DISCORD_LIST_COMMAND_EXPIRATION:-10}"
export DISCORD_LIST_COMMAND_DELETE_REQUEST="${DISCORD_LIST_COMMAND_DELETE_REQUEST:-true}"
export DISCORD_TOPIC_UPDATE_AT_SHUTDOWN="${DISCORD_TOPIC_UPDATE_AT_SHUTDOWN:-true}"
export DISCORD_TOPIC_UPDATE_RATE="${DISCORD_TOPIC_UPDATE_RATE:-10}"
export DISCORD_LINKED_ROLE_ID="${DISCORD_LINKED_ROLE_ID:-}"
export DISCORD_ALLOW_RELINK="${DISCORD_ALLOW_RELINK:-false}"
export DISCORD_LINKED_USE_PM="${DISCORD_LINKED_USE_PM:-true}"
export DISCORD_LINKED_DELETE_SECONDS="${DISCORD_LINKED_DELETE_SECONDS:-0}"
export DISCORD_WATCHDOG_ENABLED="${DISCORD_WATCHDOG_ENABLED:-true}"
export DISCORD_WATCHDOG_TIMEOUT="${DISCORD_WATCHDOG_TIMEOUT:-30}"
export DISCORD_WATCHDOG_MESSAGE_COUNT="${DISCORD_WATCHDOG_MESSAGE_COUNT:-3}"
export DISCORD_PROXY_HOST="${DISCORD_PROXY_HOST:-}"
export DISCORD_PROXY_PORT="${DISCORD_PROXY_PORT:-0}"
export DISCORD_PROXY_USER="${DISCORD_PROXY_USER:-}"
export DISCORD_PROXY_PASSWORD="${DISCORD_PROXY_PASSWORD:-}"

# Geyser defaults
export GEYSER_PORT="${GEYSER_PORT:-19132}"
export GEYSER_CLONE_REMOTE_PORT="${GEYSER_CLONE_REMOTE_PORT:-false}"
export GEYSER_MOTD1="${GEYSER_MOTD1:-Geyser}"
export GEYSER_MOTD2="${GEYSER_MOTD2:-Another Geyser server.}"
export GEYSER_SERVER_NAME="${GEYSER_SERVER_NAME:-Geyser}"
export GEYSER_COMPRESSION_LEVEL="${GEYSER_COMPRESSION_LEVEL:-6}"
export GEYSER_BEDROCK_PROXY_PROTOCOL="${GEYSER_BEDROCK_PROXY_PROTOCOL:-false}"
export GEYSER_REMOTE_ADDRESS="${GEYSER_REMOTE_ADDRESS:-auto}"
export GEYSER_REMOTE_PORT="${GEYSER_REMOTE_PORT:-25565}"
export GEYSER_AUTH_TYPE="${GEYSER_AUTH_TYPE:-online}"
export GEYSER_REMOTE_PROXY_PROTOCOL="${GEYSER_REMOTE_PROXY_PROTOCOL:-false}"
export GEYSER_FORWARD_HOSTNAME="${GEYSER_FORWARD_HOSTNAME:-false}"
export GEYSER_FLOODGATE_KEY="${GEYSER_FLOODGATE_KEY:-key.pem}"
export GEYSER_AUTH_TIMEOUT="${GEYSER_AUTH_TIMEOUT:-120}"
export GEYSER_COMMAND_SUGGESTIONS="${GEYSER_COMMAND_SUGGESTIONS:-true}"
export GEYSER_PASSTHROUGH_MOTD="${GEYSER_PASSTHROUGH_MOTD:-true}"
export GEYSER_PASSTHROUGH_PLAYER_COUNTS="${GEYSER_PASSTHROUGH_PLAYER_COUNTS:-true}"
export GEYSER_LEGACY_PING_PASSTHROUGH="${GEYSER_LEGACY_PING_PASSTHROUGH:-false}"
export GEYSER_PING_INTERVAL="${GEYSER_PING_INTERVAL:-3}"
export GEYSER_FORWARD_PLAYER_PING="${GEYSER_FORWARD_PLAYER_PING:-false}"

echo "✓ Default values set"
echo ""

# Function to get snapshot of current environment variables
# Only includes variables that are used in templates
get_env_snapshot() {
    # Export all relevant environment variables to a sorted snapshot
    env | grep -E '^(DISCORD_|GEYSER_|FLOODGATE_|BLUEMAP_|MINECRAFT_|SERVER_|LEVEL_|RCON_|GAMEMODE|DIFFICULTY|PVP|ONLINE_MODE|VIEW_DISTANCE|SIMULATION_DISTANCE|MAX_PLAYERS|MOTD|ENVIRONMENT|DEBUG|BUNGEECORD|WHITELIST|ALLOW_|ENABLE_|SPAWN_|HARDCORE)' | sort
}

# Function to check if configs need regeneration
needs_regeneration() {
    # Force regeneration if flag is set
    if [ "${MINECRAFT_FORCE_CONFIG_REGEN:-false}" = "true" ]; then
        echo "Force regeneration flag detected (MINECRAFT_FORCE_CONFIG_REGEN=true)"
        return 0
    fi
    
    # If no snapshot exists, we need to generate
    if [ ! -f "$ENV_SNAPSHOT_FILE" ]; then
        echo "No environment snapshot found - first run or /data was cleared"
        return 0
    fi
    
    # Compare current environment with saved snapshot
    local current_snapshot=$(get_env_snapshot)
    local saved_snapshot=$(cat "$ENV_SNAPSHOT_FILE")
    
    if [ "$current_snapshot" != "$saved_snapshot" ]; then
        echo "Environment variables have changed since last run"
        echo ""
        echo "Changes detected:"
        diff -u <(echo "$saved_snapshot") <(echo "$current_snapshot") | grep -E '^\+[^+]|^-[^-]' | head -20 || true
        echo ""
        return 0
    fi
    
    echo "No environment changes detected - skipping template processing"
    return 1
}

# Function to save environment snapshot
save_env_snapshot() {
    get_env_snapshot > "$ENV_SNAPSHOT_FILE"
    echo "✓ Environment snapshot saved to $ENV_SNAPSHOT_FILE"
}

# Function to process a template file
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    echo "Processing: $(basename "$template_file") -> $output_file"
    
    # Create output directory if needed
    mkdir -p "$(dirname "$output_file")"
    
    # Use envsubst if available, otherwise use perl
    if command -v envsubst &> /dev/null; then
        envsubst < "$template_file" > "$output_file"
    else
        # Basic variable substitution using perl (more reliable than sed for this)
        perl -pe 's/\$\{([^}]+)\}/$ENV{$1}/g' "$template_file" > "$output_file"
    fi
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Generated successfully"
    else
        echo "  ✗ Failed to generate"
        return 1
    fi
}

# Create temporary directory for processed configs
mkdir -p "$TEMP_DIR"

# Check if we need to process templates
SHOULD_PROCESS=false

if [ ! -d "/templates" ]; then
    echo "No templates directory found, skipping template processing"
    echo ""
elif needs_regeneration; then
    SHOULD_PROCESS=true
fi

# Process templates if needed
if [ "$SHOULD_PROCESS" = "true" ]; then
    echo "Processing templates..."
    echo ""
    
    # Process server configuration templates
    if [ -d "/templates/server" ]; then
        echo "Processing server configuration templates..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/server/}"
            output_file="$TEMP_DIR/server/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/server -name "*.template" -type f -print0)
        echo ""
    fi
    
    # Process plugin configuration templates
    if [ -d "/templates/plugins" ]; then
        echo "Processing plugin configuration templates..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/plugins/}"
            output_file="$TEMP_DIR/plugins/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/plugins -name "*.template" -type f -print0)
        echo ""
    fi
    
    echo "✓ Template processing complete!"
    echo ""
    
    # Set an environment variable to tell us to copy configs after /data is ready
    export MINECRAFT_CONFIGS_TEMP="$TEMP_DIR"
    export MINECRAFT_CONFIGS_GENERATED="true"
else
    echo "✓ Using existing configurations"
    echo ""
    export MINECRAFT_CONFIGS_GENERATED="false"
fi

echo "======================================"
echo "Starting Minecraft Server..."
echo "======================================"
echo ""

# Create a wrapper script that will copy configs after /data is initialized
cat > /tmp/post-init.sh << 'WRAPPER_EOF'
#!/bin/bash
# This script runs after /start initializes /data

# Wait a moment for /data to be fully initialized
sleep 2

# Only copy configs if we generated new ones
if [ "$MINECRAFT_CONFIGS_GENERATED" = "true" ] && [ -n "$MINECRAFT_CONFIGS_TEMP" ] && [ -d "$MINECRAFT_CONFIGS_TEMP" ]; then
    echo ""
    echo "======================================"
    echo "Copying processed configurations..."
    echo "======================================"
    
    # Copy server configs
    if [ -d "$MINECRAFT_CONFIGS_TEMP/server" ]; then
        echo "Copying server configurations..."
        cp -rv "$MINECRAFT_CONFIGS_TEMP/server/"* /data/ 2>/dev/null || true
    fi
    
    # Copy plugin configs
    if [ -d "$MINECRAFT_CONFIGS_TEMP/plugins" ]; then
        echo "Copying plugin configurations..."
        mkdir -p /data/plugins
        cp -rv "$MINECRAFT_CONFIGS_TEMP/plugins/"* /data/plugins/ 2>/dev/null || true
    fi
    
    echo "✓ Configuration copy complete!"
    echo ""
    
    # Save environment snapshot after successful copy
    ENV_SNAPSHOT_FILE="/data/.env_snapshot"
    env | grep -E '^(DISCORD_|GEYSER_|FLOODGATE_|BLUEMAP_|MINECRAFT_|SERVER_|LEVEL_|RCON_|GAMEMODE|DIFFICULTY|PVP|ONLINE_MODE|VIEW_DISTANCE|SIMULATION_DISTANCE|MAX_PLAYERS|MOTD|ENVIRONMENT|DEBUG|BUNGEECORD|WHITELIST|ALLOW_|ENABLE_|SPAWN_|HARDCORE)' | sort > "$ENV_SNAPSHOT_FILE"
    echo "✓ Environment snapshot saved"
    echo ""
else
    echo ""
    echo "======================================"
    echo "Skipping configuration copy"
    echo "======================================"
    echo "Using existing configurations from /data"
    echo ""
fi
WRAPPER_EOF

chmod +x /tmp/post-init.sh

# Set environment variable to run our post-init script
export CFG_SCRIPT_FILES="/tmp/post-init.sh"

# Execute the original entrypoint script from the base image
exec /start
