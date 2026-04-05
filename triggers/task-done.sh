#!/bin/bash
# task-done.sh — Task completed, resume music
# Usage: bash triggers/task-done.sh "task name"

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MSG="${1:-Task completed}"

# Resume music
bash "$PLUGIN_DIR/channels/sound.sh" resume

# Alert sound
bash "$PLUGIN_DIR/channels/sound.sh" alert

# macOS notification
bash "$PLUGIN_DIR/channels/macos.sh" "✅ Done" "$MSG" "Glass"

# Telegram
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  bash "$PLUGIN_DIR/channels/telegram.sh" "✅ Tamamlandı: $MSG" "✅"
fi
