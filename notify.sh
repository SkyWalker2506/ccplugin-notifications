#!/bin/bash
# notify.sh — Unified notification entry point
# Usage: bash notify.sh [--channel telegram|macos|sound|all] [--event build-error|ai-question|task-done] [--message "text"]
#
# Examples:
#   bash notify.sh --message "Deploy done" --channel all
#   bash notify.sh --event build-error --message "flutter build failed"
#   bash notify.sh --event ai-question --message "Approve migration?"
#   bash notify.sh --channel telegram --message "Backup complete" --emoji "💾"

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load secrets
[ -f "$HOME/.claude/secrets/secrets.env" ] && source "$HOME/.claude/secrets/secrets.env" 2>/dev/null
[ -f "$HOME/Projects/claude-config/claude-secrets/secrets.env" ] && source "$HOME/Projects/claude-config/claude-secrets/secrets.env" 2>/dev/null

CHANNEL="all"
EVENT=""
MESSAGE="Notification"
EMOJI="🤖"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel)  CHANNEL="$2"; shift 2 ;;
    --event)    EVENT="$2"; shift 2 ;;
    --message)  MESSAGE="$2"; shift 2 ;;
    --emoji)    EMOJI="$2"; shift 2 ;;
    *)          MESSAGE="$1"; shift ;;
  esac
done

# Event → trigger
if [ -n "$EVENT" ]; then
  bash "$PLUGIN_DIR/triggers/${EVENT}.sh" "$MESSAGE" 2>/dev/null
  exit 0
fi

# Channel dispatch
case "$CHANNEL" in
  telegram)
    bash "$PLUGIN_DIR/channels/telegram.sh" "$MESSAGE" "$EMOJI"
    ;;
  macos)
    bash "$PLUGIN_DIR/channels/macos.sh" "Claude Code" "$MESSAGE"
    ;;
  sound)
    bash "$PLUGIN_DIR/channels/sound.sh" alert
    ;;
  all)
    bash "$PLUGIN_DIR/channels/sound.sh" alert
    bash "$PLUGIN_DIR/channels/macos.sh" "Claude Code" "$MESSAGE"
    [ -n "$TELEGRAM_BOT_TOKEN" ] && bash "$PLUGIN_DIR/channels/telegram.sh" "$MESSAGE" "$EMOJI"
    ;;
esac
