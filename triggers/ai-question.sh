#!/bin/bash
# ai-question.sh — DevFocus: Claude is waiting for user input
# Called by Claude Code hooks on PreToolUse when asking user
# Usage: bash triggers/ai-question.sh "question"

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MSG="${1:-Claude is waiting for your input}"

# Pause music (you'll want to focus)
bash "$PLUGIN_DIR/channels/sound.sh" pause

# Alert sound
bash "$PLUGIN_DIR/channels/sound.sh" alert

# Bring terminal to front
osascript -e 'tell application "Terminal" to activate' 2>/dev/null

# macOS notification
bash "$PLUGIN_DIR/channels/macos.sh" "🤖 Claude needs you" "$MSG" "Ping"

# Telegram
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  bash "$PLUGIN_DIR/channels/telegram.sh" "🤖 Claude bekliyor: $MSG" "🤖"
fi
