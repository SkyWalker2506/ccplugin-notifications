#!/bin/bash
# sound.sh — Music pause/resume + alert sound (DevFocus)
# Usage: bash channels/sound.sh [pause|resume|alert]

ACTION="${1:-alert}"

pause_music() {
  # Spotify
  osascript -e 'tell application "Spotify" to pause' 2>/dev/null
  # Apple Music
  osascript -e 'tell application "Music" to pause' 2>/dev/null
}

resume_music() {
  osascript -e 'tell application "Spotify" to play' 2>/dev/null
  osascript -e 'tell application "Music" to play' 2>/dev/null
}

play_alert() {
  # Mute kontrolü
  if [ -f "$HOME/.claude/notifications-mute" ]; then
    exit 0
  fi
  if command -v afplay &>/dev/null; then
    afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
  fi
}

case "$ACTION" in
  pause)  pause_music ;;
  resume) resume_music ;;
  alert)  play_alert ;;
  *)      play_alert ;;
esac
