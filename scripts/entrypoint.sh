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

# Process templates if they exist
if [ -d "/templates" ]; then
    echo "Found templates directory, processing templates..."
    echo ""
    
    # Process server configuration templates
    if [ -d "/templates/server" ]; then
        echo "Processing server configuration templates..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/server/}"
            output_file="/data/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/server -name "*.template" -type f -print0)
        echo ""
    fi
    
    # Process plugin configuration templates
    if [ -d "/templates/plugins" ]; then
        echo "Processing plugin configuration templates..."
        while IFS= read -r -d '' template_file; do
            rel_path="${template_file#/templates/plugins/}"
            output_file="/data/plugins/${rel_path%.template}"
            process_template "$template_file" "$output_file"
        done < <(find /templates/plugins -name "*.template" -type f -print0)
        echo ""
    fi
    
    echo "✓ Template processing complete!"
    echo ""
else
    echo "No templates directory found, skipping template processing"
    echo ""
fi

echo "======================================"
echo "Starting Minecraft Server..."
echo "======================================"
echo ""

# Execute the original entrypoint script from the base image
exec /start
