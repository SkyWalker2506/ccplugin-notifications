#!/bin/bash
# sound.sh — Music pause/resume + alert sound (DevFocus)
# Usage: bash channels/sound.sh [pause|resume|alert] [--sound <name>]

# Platform guard
if [[ "$(uname)" != "Darwin" ]]; then
  exit 0
fi

ACTION="${1:-alert}"
SOUND_NAME=""

# Parse --sound flag
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sound) SOUND_NAME="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Read default sound from config if not passed
if [ -z "$SOUND_NAME" ]; then
  CONFIG="$HOME/.claude/notifications-config.json"
  if [ -f "$CONFIG" ] && command -v python3 &>/dev/null; then
    SOUND_NAME=$(python3 -c "
import json
try:
    d = json.load(open('$CONFIG'))
    print(d.get('sound', 'Glass'))
except Exception:
    print('Glass')
" 2>/dev/null)
  fi
  SOUND_NAME="${SOUND_NAME:-Glass}"
fi

SOUND_FILE="/System/Library/Sounds/${SOUND_NAME}.aiff"
# Fallback if sound file doesn't exist
[ -f "$SOUND_FILE" ] || SOUND_FILE="/System/Library/Sounds/Glass.aiff"

pause_music() {
  osascript -e 'tell application "Spotify" to pause' 2>/dev/null || true
  osascript -e 'tell application "Music" to pause' 2>/dev/null || true
}

resume_music() {
  osascript -e 'tell application "Spotify" to play' 2>/dev/null || true
  osascript -e 'tell application "Music" to play' 2>/dev/null || true
}

play_alert() {
  # Mute check
  if [ -f "$HOME/.claude/notifications-mute" ]; then
    exit 0
  fi
  if command -v afplay &>/dev/null; then
    afplay "$SOUND_FILE" 2>/dev/null &
  fi
}

case "$ACTION" in
  pause)  pause_music ;;
  resume) resume_music ;;
  alert)  play_alert ;;
  *)      play_alert ;;
esac
