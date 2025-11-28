#!/bin/bash
# Usage: add-server-icon.sh [ICON_URL]
# If ICON_URL is provided, downloads it. Otherwise, copies local server-icon.png if present.
set -e

ICON_PATH="/data/server-icon.png"

if [ -n "$1" ]; then
  echo "Downloading server icon from $1 ..."
  curl -fsSL "$1" -o "$ICON_PATH"
  chown minecraft:minecraft "$ICON_PATH"
else
  if [ -f /tmp/server-icon.png ]; then
    echo "Copying local server-icon.png ..."
    cp /tmp/server-icon.png "$ICON_PATH"
    chown minecraft:minecraft "$ICON_PATH"
  else
    echo "No server icon provided. Skipping."
  fi
fi
