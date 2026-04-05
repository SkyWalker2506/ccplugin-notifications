#!/bin/bash
# notify.sh — Sesli + Telegram bildirimi gönder
# Kullanım: notify.sh "mesaj" [emoji] [inline_buttons_json]
# Örnek:    notify.sh "Devam edeyim mi?" "🤔" '[["Evet","evet"],["Hayır","hayır"]]'
# Ses aç/kapa: CLAUDE_SOUND=1 (açık) / CLAUDE_SOUND=0 (kapalı)

MSG="${1:-Bildirim}"
EMOJI="${2:-🤖}"
BUTTONS="${3:-}"  # JSON: [["Label","data"],["Label2","data2"]]

# Sesli bildirim (macOS)
SOUND_ENABLED="${CLAUDE_SOUND:-1}"
if [ "$SOUND_ENABLED" = "1" ] && command -v afplay &>/dev/null; then
  afplay /System/Library/Sounds/Glass.aiff &
fi

SECRETS_FILE="$HOME/Projects/claude-config/claude-secrets/secrets.env"
[ -f "$SECRETS_FILE" ] && source "$SECRETS_FILE"
[ -z "$TELEGRAM_BOT_TOKEN" ] && source "$HOME/.claude/secrets/secrets.env" 2>/dev/null

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "⚠️  notify.sh: TELEGRAM_BOT_TOKEN veya TELEGRAM_CHAT_ID eksik" >&2
  exit 1
fi

FULL_MSG="$EMOJI *Claude Code*
$MSG

\`$(date '+%H:%M')\` · \`$(basename "$PWD")\`"

# Inline keyboard oluştur
MARKUP=""
if [ -n "$BUTTONS" ]; then
  MARKUP=$(python3 -c "
import json, sys
buttons = json.loads('$BUTTONS')
keyboard = [[{'text': b[0], 'callback_data': b[1]} for b in buttons]]
print(json.dumps({'inline_keyboard': keyboard}))
" 2>/dev/null)
fi

if [ -n "$MARKUP" ]; then
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
print(json.dumps({
    'chat_id': '$TELEGRAM_CHAT_ID',
    'parse_mode': 'Markdown',
    'text': '''$FULL_MSG''',
    'reply_markup': $MARKUP
}))
")" -o /dev/null
else
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="Markdown" \
    -d text="$FULL_MSG" \
    -o /dev/null
fi

exit 0
