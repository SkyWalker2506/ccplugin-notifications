#!/bin/bash
# telegram.sh — Telegram mesaj gönder (sadece Telegram, ses yok)
# Usage: bash channels/telegram.sh "mesaj" [emoji] [buttons_json]

MSG="${1:-Bildirim}"
EMOJI="${2:-🤖}"
BUTTONS="${3:-}"

# Secrets yükle
[ -f "$HOME/.claude/secrets/secrets.env" ] && source "$HOME/.claude/secrets/secrets.env" 2>/dev/null
[ -f "$HOME/Projects/claude-config/claude-secrets/secrets.env" ] && source "$HOME/Projects/claude-config/claude-secrets/secrets.env" 2>/dev/null

# Token yoksa sessizce çık
[ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ] && exit 0

FULL_MSG="$EMOJI *Claude Code*
$MSG

\`$(date '+%H:%M')\` · \`$(basename "$PWD")\`"

if [ -n "$BUTTONS" ]; then
  MARKUP=$(python3 -c "
import json
buttons = json.loads('$BUTTONS')
keyboard = [[{'text': b[0], 'callback_data': b[1]} for b in buttons]]
print(json.dumps({'inline_keyboard': keyboard}))
" 2>/dev/null)
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
print(json.dumps({'chat_id': '$TELEGRAM_CHAT_ID', 'parse_mode': 'Markdown', 'text': '''$FULL_MSG''', 'reply_markup': $MARKUP}))
")" -o /dev/null
else
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="Markdown" \
    -d text="$FULL_MSG" \
    -o /dev/null
fi
