#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HS_DIR="$HOME/.hammerspoon"
SRC="$SCRIPT_DIR/src/calendar-events.swift"
DEST="$HS_DIR/bin/calendar-events"
PLIST_SRC="$SCRIPT_DIR/com.sethvoltz.calendar-events.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.sethvoltz.calendar-events.plist"
LABEL="com.sethvoltz.calendar-events"

# Compile Swift binary
if [ ! -f "$SRC" ]; then
  echo "  Source not found: $SRC"
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
mkdir -p "$HS_DIR/cache"

if [ "$SRC" -nt "$DEST" ] || [ ! -f "$DEST" ]; then
  echo "  Compiling calendar-events..."
  swiftc -O "$SRC" -o "$DEST" -framework EventKit -framework Foundation
  echo "  Done"
else
  echo "  calendar-events binary is up-to-date"
fi

# Install LaunchAgent
if [ -f "$PLIST_SRC" ]; then
  # Unload existing agent if running
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

  # Template the plist with actual paths
  if [ ! -f "$PLIST_DEST" ]; then
    mkdir -p "$(dirname "$PLIST_DEST")"
    touch "$PLIST_DEST"
  fi
  sed "s|__HAMMERSPOON_DIR__|$HS_DIR|g" "$PLIST_SRC" > "$PLIST_DEST"

  # Load the agent
  launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
  echo "  LaunchAgent installed and loaded"
else
  echo "  LaunchAgent plist not found: $PLIST_SRC"
fi
