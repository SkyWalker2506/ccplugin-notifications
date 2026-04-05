#!/bin/bash
# notify.sh — Ses + macOS bildirimi (sadece)
# Telegram için ccplugin-telegram gerekli.
#
# Usage: bash notify.sh [--channel macos|sound|all] [--message "text"] [--emoji "🔔"]
#        bash notify.sh "mesaj" "emoji"   ← eski format uyumlu

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

CHANNEL="all"
MESSAGE="Notification"
EMOJI="🤖"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --channel)  CHANNEL="$2"; shift 2 ;;
    --message)  MESSAGE="$2"; shift 2 ;;
    --emoji)    EMOJI="$2"; shift 2 ;;
    --event)    bash "$PLUGIN_DIR/triggers/${2}.sh" "$MESSAGE" 2>/dev/null; exit 0 ;;
    --buttons)  shift 2 ;;  # Telegram'a ait, burada yoksay
    *)          MESSAGE="${1:-$MESSAGE}"; EMOJI="${2:-$EMOJI}"; break ;;
  esac
done

_sound() {
  bash "$PLUGIN_DIR/channels/sound.sh" alert 2>/dev/null
}

_macos() {
  bash "$PLUGIN_DIR/channels/macos.sh" "Claude Code" "$MESSAGE" 2>/dev/null
}

case "$CHANNEL" in
  sound)   _sound ;;
  macos)   _macos ;;
  telegram)
    echo "⚠️  Telegram bu plugin kapsamında değil." >&2
    echo "   Kurmak için: bash <(curl -fsSL https://raw.githubusercontent.com/SkyWalker2506/claude-marketplace/main/install.sh) telegram" >&2
    ;;
  all|*)
    _sound
    _macos
    ;;
esac
