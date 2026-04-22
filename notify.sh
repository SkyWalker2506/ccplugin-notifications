#!/bin/bash
# notify.sh — Sound + macOS notifications
# For Telegram support: install ccplugin-telegram
#
# Usage: bash notify.sh [--channel macos|sound|all] [--message "text"] [--emoji "emoji"] [--sound <name>]
#        bash notify.sh "message" "emoji"   <- legacy format compatible
#        bash notify.sh --list              <- show notification history
#        bash notify.sh --test              <- test all configured channels

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
HISTORY_LOG="$HOME/.claude/notification-history.log"

CHANNEL="all"
MESSAGE="Notification"
EMOJI="(i)"
SOUND_NAME=""

# Platform guard
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Warning: ccplugin-notifications is macOS-only. Sound and native notifications unavailable." >&2
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel)  CHANNEL="$2"; shift 2 ;;
    --message)  MESSAGE="$2"; shift 2 ;;
    --emoji)    EMOJI="$2"; shift 2 ;;
    --sound)    SOUND_NAME="$2"; shift 2 ;;
    --event)    bash "$PLUGIN_DIR/triggers/${2}.sh" "$MESSAGE" 2>/dev/null; exit 0 ;;
    --buttons)  shift 2 ;;  # Telegram-specific, ignored here
    --list)
      echo "--- Notification History (last 20) ---"
      tail -20 "$HISTORY_LOG" 2>/dev/null || echo "(no history yet)"
      exit 0
      ;;
    --test)
      echo "Testing notification channels..."
      bash "$PLUGIN_DIR/channels/sound.sh" alert && echo "  sound: OK" || echo "  sound: FAILED"
      bash "$PLUGIN_DIR/channels/macos.sh" "Test" "ccplugin-notifications test" && echo "  macos: OK" || echo "  macos: FAILED"
      echo "All channel tests done."
      exit 0
      ;;
    *)  MESSAGE="${1:-$MESSAGE}"; EMOJI="${2:-$EMOJI}"; break ;;
  esac
done

_log() {
  mkdir -p "$(dirname "$HISTORY_LOG")"
  echo "$(date -u +%FT%TZ) [${CHANNEL}] ${EMOJI} ${MESSAGE}" >> "$HISTORY_LOG"
}

_sound() {
  bash "$PLUGIN_DIR/channels/sound.sh" alert ${SOUND_NAME:+"--sound" "$SOUND_NAME"} 2>/dev/null
}

_macos() {
  bash "$PLUGIN_DIR/channels/macos.sh" "Claude Code" "$MESSAGE" 2>/dev/null
}

case "$CHANNEL" in
  sound)
    _sound
    _log
    ;;
  macos)
    _macos
    _log
    ;;
  telegram)
    echo "Warning: Telegram is not part of ccplugin-notifications." >&2
    echo "  Install: bash <(curl -fsSL https://raw.githubusercontent.com/SkyWalker2506/claude-marketplace/main/install.sh) telegram" >&2
    ;;
  all|*)
    _sound
    _macos
    _log
    ;;
esac
