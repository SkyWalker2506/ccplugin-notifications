#!/bin/bash
# ccplugin-notifications — Standalone installer
# Works independently — no claude-config required

set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "=== ccplugin-notifications installer ==="

# Install to ~/.claude/skills/notifications/
DEST="$HOME/.claude/skills/notifications"
mkdir -p "$DEST"
cp -r "$PLUGIN_DIR/"* "$DEST/" 2>/dev/null || true
rm -rf "$DEST/.git" 2>/dev/null || true
chmod +x "$DEST/notify.sh" "$DEST/install.sh" 2>/dev/null || true
chmod +x "$DEST/channels/"*.sh 2>/dev/null || true
chmod +x "$DEST/triggers/"*.sh 2>/dev/null || true

# Backward compat symlinks (if claude-config exists)
CLAUDE_CONFIG="${CLAUDE_CONFIG_DIR:-$HOME/Projects/claude-config}"
if [ -d "$CLAUDE_CONFIG/config" ]; then
  ln -sf "$DEST/channels/telegram.sh" "$CLAUDE_CONFIG/config/notify.sh" 2>/dev/null || true
  ln -sf "$DEST/notify.sh" "$CLAUDE_CONFIG/config/notify-unified.sh" 2>/dev/null || true
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
echo "  bash notify.sh --message 'Deploy done' --channel all"
echo "  bash notify.sh --event build-error --message 'flutter failed'"
echo ""
echo "Tam sistem için (auto-dispatch, 134 agent, 36 skill, MCP):"
echo "  git clone https://github.com/SkyWalker2506/claude-config ~/Projects/claude-config"
echo "  cd ~/Projects/claude-config && ./install.sh"
