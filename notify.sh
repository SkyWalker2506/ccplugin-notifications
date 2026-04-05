#!/bin/bash
# notify.sh — Unified notification entry point
# Usage: bash notify.sh [--channel telegram|macos|sound|all] [--message "text"] [--emoji "🔔"] [--buttons json]
#
# Telegram desteği için ccplugin-telegram kurulu olmalı veya
# TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID secrets.env'de tanımlı olmalı.
#
# Examples:
#   bash notify.sh --message "Deploy done"
#   bash notify.sh --channel sound
#   bash notify.sh --channel telegram --message "Backup complete" --emoji "💾"

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

# Secrets yükle
[ -f "$HOME/.claude/secrets/secrets.env" ] && source "$HOME/.claude/secrets/secrets.env" 2>/dev/null
[ -f "$HOME/Projects/claude-config/claude-secrets/secrets.env" ] && source "$HOME/Projects/claude-config/claude-secrets/secrets.env" 2>/dev/null

CHANNEL="all"
EVENT=""
MESSAGE="Notification"
EMOJI="🤖"
BUTTONS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel)  CHANNEL="$2"; shift 2 ;;
    --event)    EVENT="$2"; shift 2 ;;
    --message)  MESSAGE="$2"; shift 2 ;;
    --emoji)    EMOJI="$2"; shift 2 ;;
    --buttons)  BUTTONS="$2"; shift 2 ;;
    # Eski positional format uyumluluğu: notify.sh "mesaj" "emoji"
    *)          [ -z "$1" ] || MESSAGE="$1"; [ -z "$2" ] || EMOJI="$2"; break ;;
  esac
done

# Event → trigger
if [ -n "$EVENT" ]; then
  bash "$PLUGIN_DIR/triggers/${EVENT}.sh" "$MESSAGE" 2>/dev/null
  exit 0
fi

_send_sound() {
  bash "$PLUGIN_DIR/channels/sound.sh" alert 2>/dev/null
}

_send_macos() {
  bash "$PLUGIN_DIR/channels/macos.sh" "Claude Code" "$MESSAGE" 2>/dev/null
}

_send_telegram() {
  if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    bash "$PLUGIN_DIR/channels/telegram.sh" "$MESSAGE" "$EMOJI" "$BUTTONS" 2>/dev/null
  else
    # Telegram token yok — sessiz geç, kullanıcı isterse ccplugin-telegram kurabilir
    : # hint: bash <(curl -fsSL https://raw.githubusercontent.com/SkyWalker2506/claude-marketplace/main/install.sh) telegram
  fi
}

case "$CHANNEL" in
  telegram)
    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
      echo "⚠️  Telegram kurulu değil. Kurmak için:" >&2
      echo "   bash <(curl -fsSL https://raw.githubusercontent.com/SkyWalker2506/claude-marketplace/main/install.sh) telegram" >&2
      exit 0
    fi
    _send_telegram
    ;;
  macos)
    _send_macos
    ;;
  sound)
    _send_sound
    ;;
  all)
    _send_sound
    _send_macos
    _send_telegram   # token varsa gönderir, yoksa sessiz geçer
    ;;
esac
