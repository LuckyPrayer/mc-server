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
# Process templates directly to /config so base image can copy them to /data
# This ensures configs are ready before plugins initialize
CONFIG_DIR="/config"

# Load default values for environment variables from organized defaults files
# This allows templates to use simple ${VAR} syntax instead of ${VAR:-default}
echo "Loading default environment variables..."

# Function to load defaults files conditionally
load_defaults() {
    local defaults_dir="/defaults"
    
    # Always load core server defaults
    if [ -f "${defaults_dir}/core.env" ]; then
        echo "  → Loading core server defaults"
        source "${defaults_dir}/core.env"
    fi
    
    # Load plugin defaults only if their template directories exist
    if [ -d "/templates/plugins/DiscordSRV" ] && [ -f "${defaults_dir}/discord.env" ]; then
        echo "  → Loading DiscordSRV plugin defaults"
        source "${defaults_dir}/discord.env"
    fi
    
    if [ -d "/templates/plugins/Geyser-Spigot" ] && [ -f "${defaults_dir}/geyser.env" ]; then
        echo "  → Loading Geyser plugin defaults"
        source "${defaults_dir}/geyser.env"
    fi
    
    if [ -d "/templates/plugins/Floodgate" ] && [ -f "${defaults_dir}/floodgate.env" ]; then
        echo "  → Loading Floodgate plugin defaults"
        source "${defaults_dir}/floodgate.env"
    fi
    
    if [ -d "/templates/plugins/BlueMap" ] && [ -f "${defaults_dir}/bluemap.env" ]; then
        echo "  → Loading BlueMap plugin defaults"
        source "${defaults_dir}/bluemap.env"
    fi
}

# Load all relevant defaults
load_defaults

echo "✓ Default values loaded"
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

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

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
    
    # Process server configuration templates to /config (base image will copy)
    if [ -d "/templates/server" ]; then
        echo "Processing server configuration templates to $CONFIG_DIR..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/server/}"
            output_file="$CONFIG_DIR/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/server -name "*.template" -type f -print0)
        echo "  → Server configs will be copied by base image to /data"
        echo ""
    fi
    
    # Process plugin configuration templates to temporary location
    # We'll copy these directly to /data/plugins after base image initializes /data
    PLUGIN_TEMP_DIR="/tmp/minecraft-plugin-configs"
    mkdir -p "$PLUGIN_TEMP_DIR"
    
    if [ -d "/templates/plugins" ]; then
        echo "Processing plugin configuration templates to $PLUGIN_TEMP_DIR..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/plugins/}"
            output_file="$PLUGIN_TEMP_DIR/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/plugins -name "*.template" -type f -print0)
        echo "  → Plugin configs will be copied directly to /data/plugins"
        echo ""
        
        # Set flag to copy plugin configs after /data is initialized
        export MINECRAFT_PLUGIN_CONFIGS_DIR="$PLUGIN_TEMP_DIR"
    fi
    
    # Save environment snapshot to /config (base image will copy to /data)
    echo "Saving environment snapshot to $CONFIG_DIR/.env_snapshot"
    get_env_snapshot > "$CONFIG_DIR/.env_snapshot"
    
    echo "✓ Template processing complete!"
    echo ""
else
    echo "✓ Using existing configurations"
    echo ""
fi

echo "======================================"
echo "Starting Minecraft Server..."
echo "======================================"
echo ""

# Create a wrapper script to copy plugin configs after /data is initialized
if [ -n "$MINECRAFT_PLUGIN_CONFIGS_DIR" ] && [ -d "$MINECRAFT_PLUGIN_CONFIGS_DIR" ]; then
    echo "Creating post-init script to copy plugin configs..."
    
    cat > /tmp/copy-plugin-configs.sh << 'PLUGIN_COPY_EOF'
#!/bin/bash
# This script runs after base image initializes /data
# It copies plugin configs directly to /data/plugins

if [ -n "$MINECRAFT_PLUGIN_CONFIGS_DIR" ] && [ -d "$MINECRAFT_PLUGIN_CONFIGS_DIR" ]; then
    echo ""
    echo "======================================"
    echo "Copying Plugin Configurations"
    echo "======================================"
    echo "Source: $MINECRAFT_PLUGIN_CONFIGS_DIR"
    echo "Target: /data/plugins"
    echo ""
    
    # Wait a moment for /data to be fully initialized by base image
    sleep 2
    
    # Ensure /data/plugins exists
    mkdir -p /data/plugins
    
    # Copy plugin configs, preserving directory structure
    if [ "$(ls -A "$MINECRAFT_PLUGIN_CONFIGS_DIR" 2>/dev/null)" ]; then
        echo "Copying plugin configurations..."
        cp -rfv "$MINECRAFT_PLUGIN_CONFIGS_DIR"/* /data/plugins/
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✓ Plugin configurations copied successfully!"
            echo ""
            
            # List what was copied
            echo "Plugin configs in /data/plugins:"
            find /data/plugins -maxdepth 2 -name "*.yml" -o -name "*.yaml" -o -name "*.conf" -o -name "*.properties" 2>/dev/null | head -20
            echo ""
        else
            echo "✗ Failed to copy some plugin configurations"
            echo ""
        fi
    else
        echo "No plugin configurations to copy"
        echo ""
    fi
else
    echo "No plugin configurations to copy (MINECRAFT_PLUGIN_CONFIGS_DIR not set)"
fi
PLUGIN_COPY_EOF

    chmod +x /tmp/copy-plugin-configs.sh
    export CFG_SCRIPT_FILES="/tmp/copy-plugin-configs.sh"
    
    echo "✓ Post-init script created"
    echo ""
fi

echo "Base image will now:"
echo "  1. Copy server configs from $CONFIG_DIR to /data"
echo "  2. Initialize server files"
if [ -n "$MINECRAFT_PLUGIN_CONFIGS_DIR" ]; then
    echo "  3. Run post-init script to copy plugin configs to /data/plugins"
    echo "  4. Start Minecraft server"
else
    echo "  3. Start Minecraft server"
fi
echo ""

# Execute the original entrypoint script from the base image
exec /start
