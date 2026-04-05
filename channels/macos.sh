#!/bin/bash
# macos.sh — macOS native notification
# Usage: bash channels/macos.sh "Title" "Message" [sound]

TITLE="${1:-Claude Code}"
MSG="${2:-Notification}"
SOUND="${3:-Glass}"  # Glass, Ping, Sosumi, etc.

# Visual notification
osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"$SOUND\"" 2>/dev/null

# Bring Terminal/Claude to front if needed
# osascript -e 'tell application "Terminal" to activate' 2>/dev/null
