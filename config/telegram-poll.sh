#!/bin/bash
# telegram-poll.sh — Telegram → Claude Code köprüsü
# Kullanım: bash config/telegram-poll.sh [proje_dizini]

PROJECT_DIR="${1:-$HOME/Projects/claude-config}"
LOG_FILE="$HOME/.watchdog/telegram.log"
OFFSET_FILE="$HOME/.watchdog/telegram_offset"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR=$(mktemp -d)
trap "rm -rf $WORKDIR" EXIT

set -a
SECRETS_FILE="$HOME/Projects/claude-config/claude-secrets/secrets.env"
[ -f "$SECRETS_FILE" ] && source "$SECRETS_FILE"
[ -z "$TELEGRAM_BOT_TOKEN" ] && source "$HOME/.claude/secrets/secrets.env" 2>/dev/null
set +a

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "❌ Token/Chat ID eksik" >&2; exit 1
fi

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"
mkdir -p "$(dirname "$LOG_FILE")"
OFFSET=$(cat "$OFFSET_FILE" 2>/dev/null || echo "0")

log() { echo "$(date '+%H:%M:%S'): $*" | tee -a "$LOG_FILE"; }

send() {
  python3 "$SCRIPT_DIR/tg_send.py" "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$1" "${2:-}"
}

send_file() {
  curl -s -X POST "$API/sendDocument" \
    -F chat_id="$TELEGRAM_CHAT_ID" \
    -F document=@"$1" \
    -F caption="${2:-Çıktı}" -o /dev/null
}

typing() {
  curl -s -X POST "$API/sendChatAction" \
    -d chat_id="$TELEGRAM_CHAT_ID" -d action="typing" -o /dev/null &
}

download_tg_file() {
  local file_id="$1" dest="$2"
  local file_path
  file_path=$(curl -s "$API/getFile?file_id=$file_id" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('result',{}).get('file_path',''))
")
  [ -z "$file_path" ] && return 1
  curl -s "https://api.telegram.org/file/bot${TELEGRAM_BOT_TOKEN}/${file_path}" -o "$dest"
}

run_claude() {
  local task="$1"
  local out="$WORKDIR/out.txt"
  typing

  # TMUX modu: CLAUDE_TMUX_SESSION set ise mesajı direkt o terminale inject et
  if [ -n "$CLAUDE_TMUX_SESSION" ] && tmux has-session -t "$CLAUDE_TMUX_SESSION" 2>/dev/null; then
    # Önceki pane içeriğini kaydet (baseline)
    local before
    before=$(tmux capture-pane -t "$CLAUDE_TMUX_SESSION" -p 2>/dev/null | tail -5)
    # Mesajı tmux pane'e yaz — Claude'a direkt gidiyor
    tmux send-keys -t "$CLAUDE_TMUX_SESSION" "$task" Enter
    send "📨 _İletildi → Claude terminal oturumu_"
    # Yanıt bekleme: 60s boyunca çıktıyı izle, değişince oku
    local waited=0
    while [ $waited -lt 60 ]; do
      sleep 2; waited=$((waited+2))
      local current
      current=$(tmux capture-pane -t "$CLAUDE_TMUX_SESSION" -p 2>/dev/null | tail -5)
      [ "$current" != "$before" ] && before="$current"
      # Claude yanıtı tamamladı mı? prompt işareti var mı?
      if tmux capture-pane -t "$CLAUDE_TMUX_SESSION" -p 2>/dev/null | grep -q "^>"; then
        break
      fi
    done
    # Son çıktıyı yakala
    local result
    result=$(tmux capture-pane -t "$CLAUDE_TMUX_SESSION" -p -S -200 2>/dev/null \
      | sed '/^$/d' | tail -80)
    if [ ${#result} -gt 3500 ]; then
      echo "$result" > "$out"
      send_file "$out" "Çıktı"
    else
      send "💬
\`\`\`
${result}
\`\`\`" "$MAIN_KB"
    fi
    return
  fi

  # Normal mod: claude -p --continue (yeni process, aynı session context)
  send "⚙️ _Çalışıyor..._"
  (cd "$PROJECT_DIR" && timeout 300 claude -p "$task" --continue --output-format text 2>&1) > "$out"
  local result; result=$(cat "$out")
  if [ ${#result} -gt 3500 ]; then
    send_file "$out" "Çıktı ($(wc -l < "$out" | tr -d ' ') satır)"
  else
    send "✅ *Tamamlandı*

\`\`\`
${result}
\`\`\`" "$MAIN_KB"
  fi
}

MAIN_KB='{"keyboard":[[{"text":"📊 Durum"},{"text":"📁 Projeler"}],[{"text":"📋 Log"},{"text":"⏹ Durdur"}]],"resize_keyboard":true,"persistent":true}'

# Eski mesajları atla
LATEST=$(curl -s "$API/getUpdates?offset=-1" | python3 -c "
import json,sys
r=json.load(sys.stdin).get('result',[])
print(r[-1]['update_id']+1 if r else 0)
" 2>/dev/null)
[ -n "$LATEST" ] && [ "$LATEST" -gt 0 ] && OFFSET="$LATEST" && echo "$OFFSET" > "$OFFSET_FILE"

log "Polling başladı → $PROJECT_DIR (offset=$OFFSET)"
send "🟢 *Claude Code bağlandı*
Proje: \`$(basename "$PROJECT_DIR")\`
Komut ver veya mesaj yaz." "$MAIN_KB"

while true; do
  RESPONSE=$(curl -s --max-time 8 "$API/getUpdates?offset=$OFFSET&timeout=3&allowed_updates=message,callback_query" 2>/dev/null)
  [ -z "$RESPONSE" ] && sleep 2 && continue

  UPDATES="$WORKDIR/updates.txt"
  echo "$RESPONSE" | python3 "$SCRIPT_DIR/tg_parse.py" "$TELEGRAM_CHAT_ID" > "$UPDATES" 2>/dev/null
  [ ! -s "$UPDATES" ] && sleep 1 && continue

  while IFS=$'\t' read -r TYPE UPD_ID FIELD1 FIELD2; do
    [ -z "$TYPE" ] && continue
    OFFSET=$((UPD_ID + 1))
    echo "$OFFSET" > "$OFFSET_FILE"

    if [ "$TYPE" = "CB" ]; then
      curl -s -X POST "$API/answerCallbackQuery" -d callback_query_id="$FIELD1" -o /dev/null
      TEXT="$FIELD2"
    elif [ "$TYPE" = "PHOTO" ]; then
      FILE_ID="$FIELD1"
      CAPTION="$FIELD2"
      log "[PHOTO] caption=$CAPTION"
      IMGFILE="$WORKDIR/photo.jpg"
      if download_tg_file "$FILE_ID" "$IMGFILE"; then
        PROMPT="Bu resmi analiz et ve açıkla"
        [ -n "$CAPTION" ] && PROMPT="$CAPTION"
        typing
        send "🖼️ _Resim alındı, analiz ediliyor..._"
        OUT="$WORKDIR/out.txt"
        (cd "$PROJECT_DIR" && timeout 300 claude -p "$PROMPT" --continue --image "$IMGFILE" --output-format text 2>&1) > "$OUT" || \
        (cd "$PROJECT_DIR" && timeout 300 claude -p "[Resim: $IMGFILE] $PROMPT" --continue --output-format text 2>&1) > "$OUT"
        RESULT=$(cat "$OUT")
        [ ${#RESULT} -gt 3500 ] && send_file "$OUT" "Analiz" || send "✅ $RESULT" "$MAIN_KB"
      else
        send "❌ Resim indirilemedi."
      fi
      continue
    elif [ "$TYPE" = "DOC" ]; then
      FILE_ID="$FIELD1"
      FNAME_CAP="$FIELD2"
      FNAME="${FNAME_CAP%%|*}"
      CAPTION="${FNAME_CAP##*|}"
      log "[DOC] $FNAME"
      DOCFILE="$WORKDIR/$FNAME"
      if download_tg_file "$FILE_ID" "$DOCFILE"; then
        send "📄 _Dosya alındı: \`$FNAME\` — işleniyor..._"
        PROMPT="${CAPTION:-Bu dosyayı analiz et}"
        OUT="$WORKDIR/out.txt"
        # Metin dosyası ise içeriği Claude'a ver
        if file "$DOCFILE" | grep -qiE "text|json|python|shell|csv"; then
          CONTENT=$(head -c 8000 "$DOCFILE")
          (cd "$PROJECT_DIR" && timeout 300 claude -p "$PROMPT

Dosya içeriği:
\`\`\`
$CONTENT
\`\`\`" --continue --output-format text 2>&1) > "$OUT"
        else
          (cd "$PROJECT_DIR" && timeout 300 claude -p "$PROMPT (Dosya: $DOCFILE)" --continue --output-format text 2>&1) > "$OUT"
        fi
        RESULT=$(cat "$OUT")
        [ ${#RESULT} -gt 3500 ] && send_file "$OUT" "Analiz" || send "✅ $RESULT" "$MAIN_KB"
      else
        send "❌ Dosya indirilemedi."
      fi
      continue
    elif [ "$TYPE" = "VOICE" ]; then
      send "🎤 Ses mesajı alındı ama henüz desteklenmiyor." "$MAIN_KB"
      continue
    else
      TEXT="$FIELD1"
    fi

    [ -z "$TEXT" ] && continue
    log "[$TYPE] $TEXT"

    # Normalize: emoji'li buton metinlerini komuta çevir
    case "$TEXT" in
      *"Durum"*)  TEXT="/status" ;;
      *"Projeler"*) TEXT="/projects" ;;
      *"Durdur"*)  TEXT="/stop" ;;
      *"Log"*)     TEXT="/log" ;;
    esac

    case "$TEXT" in
      /stop)
        send "🔴 Durduruldu."
        exit 0 ;;
      /status)
        send "🟢 *Durum*
Proje: \`$(basename "$PROJECT_DIR")\`
Saat: \`$(date '+%H:%M:%S')\`" "$MAIN_KB" ;;
      /projects)
        PLIST=$(ls -d ~/Projects/*/ 2>/dev/null | xargs -I{} basename {} | head -10)
        send "📁 *Projeler*
\`\`\`
$PLIST
\`\`\`" "$MAIN_KB" ;;
      /cd\ *)
        NEW="${TEXT#/cd }"
        FULL="$HOME/Projects/$NEW"
        if [ -d "$FULL" ]; then
          PROJECT_DIR="$FULL"
          send "📁 Proje: \`$NEW\`" "$MAIN_KB"
        else
          send "❌ Bulunamadı: \`$NEW\`" "$MAIN_KB"
        fi ;;
      /log)
        LOG_OUT=$(tail -30 "$LOG_FILE" 2>/dev/null | sed 's/`/'"'"'/g')
        send "📋 *Son 30 satır log:*

\`\`\`
$LOG_OUT
\`\`\`" "$MAIN_KB" ;;
      /run\ *|/r\ *)
        TASK="${TEXT#/run }"; TASK="${TASK#/r }"
        run_claude "$TASK" ;;
      /help|/start)
        send "🤖 *Claude Code Bot*

\`/run <görev>\` — Claude'a görev ver
\`/status\` — Durum
\`/projects\` — Projeler
\`/cd <proje>\` — Proje değiştir
\`/log\` — Loglar
\`/stop\` — Durdur

Serbest metin → Claude'a iletilir." "$MAIN_KB" ;;
      *)
        run_claude "$TEXT" ;;
    esac

  done < "$UPDATES"
done
