#!/bin/bash
set -e

echo "======================================"
echo "Minecraft Server - Template Processor"
echo "======================================"
echo ""

# Load environment defaults
[ -f "/defaults/core.env" ] && source "/defaults/core.env"
[ -f "/defaults/discord.env" ] && source "/defaults/discord.env"
[ -f "/defaults/geyser.env" ] && source "/defaults/geyser.env"
[ -f "/defaults/floodgate.env" ] && source "/defaults/floodgate.env"
[ -f "/defaults/bluemap.env" ] && source "/defaults/bluemap.env"

echo "✓ Environment defaults loaded"

# Process template function
process_template() {
    mkdir -p "$(dirname "$2")"
    if command -v envsubst &> /dev/null; then
        envsubst < "$1" > "$2"
    else
        perl -pe 's/\$\{([^}]+)\}/$ENV{$1}/g' "$1" > "$2"
    fi
}

# Process server templates to /config
if [ -d "/templates/server" ]; then
    echo "→ Processing server templates..."
    find /templates/server -name "*.template" -type f -print0 | while IFS= read -r -d '' tmpl; do
        rel="${tmpl#/templates/server/}"
        process_template "$tmpl" "/config/${rel%.template}"
    done
fi

# Process plugin templates DIRECTLY to /data/plugins
# This ensures they exist before base image or plugins try to read them
if [ -d "/templates/plugins" ]; then
    echo "→ Processing plugin templates directly to /data/plugins..."
    find /templates/plugins -name "*.template" -type f -print0 | while IFS= read -r -d '' tmpl; do
        rel="${tmpl#/templates/plugins/}"
        dest="/data/plugins/${rel%.template}"
        process_template "$tmpl" "$dest"
        echo "  Generated: ${rel%.template}"
    done
fi

echo "✓ All templates processed!"
echo ""

# Now execute base image entrypoint
# Plugin configs are already in place, so plugins will read them correctly
exec /start
