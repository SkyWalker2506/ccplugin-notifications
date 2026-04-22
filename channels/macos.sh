#!/bin/bash
# macos.sh — macOS native notification
# Usage: bash channels/macos.sh "Title" "Message" [sound]

# Platform guard
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Warning: macos.sh requires macOS" >&2
  exit 0
fi

TITLE="${1:-Claude Code}"
MSG="${2:-Notification}"
SOUND="${3:-Glass}"  # Glass, Ping, Sosumi, Basso, etc.

# Read configurable sound from config if not explicitly passed
CONFIG="$HOME/.claude/notifications-config.json"
if [ -z "${3:-}" ] && [ -f "$CONFIG" ] && command -v python3 &>/dev/null; then
  CONFIGURED_SOUND=$(python3 -c "
import json, sys
try:
    d = json.load(open('$CONFIG'))
    print(d.get('sound', 'Glass'))
except Exception:
    print('Glass')
" 2>/dev/null)
  SOUND="${CONFIGURED_SOUND:-Glass}"
fi

# Visual notification (retry once on failure)
if ! osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"$SOUND\"" 2>/dev/null; then
  sleep 1
  osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"$SOUND\"" 2>/dev/null || true
fi
