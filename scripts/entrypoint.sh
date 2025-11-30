#!/bin/bash
# Container entrypoint script
# Processes configuration templates before starting the Minecraft server

set -e

echo "======================================"
echo "Minecraft Server - Template Processor"
echo "======================================"
echo ""

# Function to process a template file
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    echo "Processing: $(basename "$template_file") -> $output_file"
    
    # Create output directory if needed
    mkdir -p "$(dirname "$output_file")"
    
    # Use envsubst if available, otherwise use sed
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
TEMP_DIR="/tmp/minecraft-configs"
mkdir -p "$TEMP_DIR"

# Process templates if they exist
if [ -d "/templates" ]; then
    echo "Found templates directory, processing templates..."
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
else
    echo "No templates directory found, skipping template processing"
    echo ""
fi

echo "======================================"
echo "Starting Minecraft Server..."
echo "======================================"
echo ""

# Create a wrapper script that will copy configs after /data is initialized
cat > /tmp/post-init.sh << 'WRAPPER_EOF'
#!/bin/bash
# This script runs after /start initializes /data

if [ -n "$MINECRAFT_CONFIGS_TEMP" ] && [ -d "$MINECRAFT_CONFIGS_TEMP" ]; then
    echo ""
    echo "======================================"
    echo "Copying processed configurations..."
    echo "======================================"
    
    # Wait a moment for /data to be fully initialized
    sleep 2
    
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
fi
WRAPPER_EOF

chmod +x /tmp/post-init.sh

# Set environment variable to run our post-init script
export CFG_SCRIPT_FILES="/tmp/post-init.sh"

# Execute the original entrypoint script from the base image
exec /start
