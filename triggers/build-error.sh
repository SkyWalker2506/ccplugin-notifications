#!/bin/bash
# build-error.sh — DevFocus: detect build/test errors and notify
# Called by Claude Code hooks on tool errors
# Usage: bash triggers/build-error.sh "error message"

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MSG="${1:-Build error detected}"

# Pause music
bash "$PLUGIN_DIR/channels/sound.sh" pause

# Play alert
bash "$PLUGIN_DIR/channels/sound.sh" alert

# macOS notification
bash "$PLUGIN_DIR/channels/macos.sh" "🔴 Build Error" "$MSG" "Basso"

# Telegram notification (if configured)
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  bash "$PLUGIN_DIR/channels/telegram.sh" "🔴 Build error: $MSG" "🔴"
fi
