#!/bin/bash
# ccplugin-notifications — Standalone installer
# Works with or without claude-config

set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "=== ccplugin-notifications installer ==="

# Option A: Bootstrap claude-config if missing
CLAUDE_CONFIG="${CLAUDE_CONFIG_DIR:-$HOME/Projects/claude-config}"
if [ ! -d "$CLAUDE_CONFIG/.git" ]; then
  echo ""
  echo "claude-config bulunamadı ($CLAUDE_CONFIG)"
  echo "Seçenek:"
  echo "  1) claude-config'i de kur (tam sistem — önerilen)"
  echo "  2) Sadece bu plugin'i kur (standalone)"
  read -p "Seçim [1/2]: " choice
  if [ "${choice:-1}" = "1" ]; then
    echo "claude-config kuruluyor..."
    gh repo clone SkyWalker2506/claude-config "$CLAUDE_CONFIG" 2>/dev/null || \
      git clone https://github.com/SkyWalker2506/claude-config.git "$CLAUDE_CONFIG"
    cd "$CLAUDE_CONFIG" && bash ./install.sh
    exit 0
  fi
fi

# Standalone: copy files to ~/.claude/
DEST="$HOME/.claude"
mkdir -p "$DEST/skills/notifications"
cp -r "$PLUGIN_DIR/"* "$DEST/skills/notifications/" 2>/dev/null || true
chmod +x "$DEST/skills/notifications/notify.sh" 2>/dev/null || true
chmod +x "$DEST/skills/notifications/channels/"*.sh 2>/dev/null || true
chmod +x "$DEST/skills/notifications/triggers/"*.sh 2>/dev/null || true

# Symlink notify.sh to config/ for backward compat with claude-config
if [ -d "$CLAUDE_CONFIG/config" ]; then
  ln -sf "$DEST/skills/notifications/channels/telegram.sh" "$CLAUDE_CONFIG/config/notify.sh" 2>/dev/null || true
  ln -sf "$DEST/skills/notifications/notify.sh" "$CLAUDE_CONFIG/config/notify-unified.sh" 2>/dev/null || true
fi

# Secrets check
if [ -f "$HOME/.claude/secrets/secrets.env" ]; then
  source "$HOME/.claude/secrets/secrets.env" 2>/dev/null
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
    echo -e "  ${GREEN}✅ Telegram: token ayarlı${NC}"
  else
    echo -e "  ${YELLOW}⚠️  Telegram: TELEGRAM_BOT_TOKEN eksik (~/.claude/secrets/secrets.env)${NC}"
  fi
else
  echo -e "  ${YELLOW}⚠️  ~/.claude/secrets/secrets.env bulunamadı — Telegram için gerekli${NC}"
fi

echo ""
echo -e "${GREEN}✅ ccplugin-notifications kuruldu${NC}"
echo ""
echo "Kullanım:"
echo "  bash ~/.claude/skills/notifications/notify.sh --message 'Deploy done' --channel all"
echo "  bash ~/.claude/skills/notifications/notify.sh --event build-error --message 'flutter failed'"
