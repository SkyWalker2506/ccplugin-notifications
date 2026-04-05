#!/bin/bash
# telegram-wait.sh — Telegram'dan yeni mesaj bekler, gelince stdout'a yazar
# Kullanım: MSG=$(bash config/telegram-wait.sh)
# Timeout: --timeout 300 (saniye, default 600)

TIMEOUT=600
while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout) TIMEOUT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

SECRETS_FILE="$HOME/Projects/claude-config/claude-secrets/secrets.env"
[ -f "$SECRETS_FILE" ] && source "$SECRETS_FILE"
[ -z "$TELEGRAM_BOT_TOKEN" ] && source "$HOME/.claude/secrets/secrets.env" 2>/dev/null

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"
OFFSET_FILE="$HOME/.watchdog/telegram_offset"
OFFSET=$(cat "$OFFSET_FILE" 2>/dev/null || echo "0")

# En güncel mesajı baz al
LATEST=$(curl -s "$API/getUpdates?offset=-1" | python3 -c "
import json,sys
r=json.load(sys.stdin).get('result',[])
print(r[-1]['update_id']+1 if r else 0)
" 2>/dev/null)
[ -n "$LATEST" ] && [ "$LATEST" -gt "$OFFSET" ] && OFFSET="$LATEST"

DEADLINE=$(($(date +%s) + TIMEOUT))

while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  RESPONSE=$(curl -s "$API/getUpdates?offset=$OFFSET&timeout=10")
  RESULT=$(echo "$RESPONSE" | python3 -c "
import json,sys
data=json.load(sys.stdin)
for u in data.get('result',[]):
    msg=u.get('message',{})
    if str(msg.get('chat',{}).get('id',''))=='$TELEGRAM_CHAT_ID':
        text=msg.get('text','')
        uid=u['update_id']
        print(f'{uid}|||{text}')
        break
" 2>/dev/null)

  if [ -n "$RESULT" ]; then
    UPDATE_ID=$(echo "$RESULT" | python3 -c "import sys; print(sys.stdin.read().strip().split('|||')[0])")
    TEXT=$(echo "$RESULT"      | python3 -c "import sys; p=sys.stdin.read().strip().split('|||'); print('|||'.join(p[1:]))")
    OFFSET=$((UPDATE_ID + 1))
    echo "$OFFSET" > "$OFFSET_FILE"
    echo "$TEXT"
    exit 0
  fi
done

echo ""
exit 1
