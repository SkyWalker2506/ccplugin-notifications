#!/bin/bash
# telegram-ask.sh — Terminal veya Telegram'dan hangisi önce gelirse onu kabul et
# Kullanım: CEVAP=$(bash config/telegram-ask.sh "Soru?" "emoji" timeout_sn)

SORU="${1:-Devam edeyim mi?}"
EMOJI="${2:-🤖}"
TIMEOUT="${3:-600}"

NOTIFY="$HOME/Projects/claude-config/config/notify.sh"
WAIT="$HOME/Projects/claude-config/config/telegram-wait.sh"

TMPFILE=$(mktemp)
PIDFILE=$(mktemp)

# Telegram'a sor
bash "$NOTIFY" "$SORU" "$EMOJI" 2>/dev/null

# Telegram'ı arka planda bekle
(
  RESULT=$(bash "$WAIT" --timeout "$TIMEOUT" 2>/dev/null)
  if [ -n "$RESULT" ] && [ ! -s "$TMPFILE" ]; then
    echo "$RESULT" > "$TMPFILE"
  fi
) &
TG_PID=$!

# Terminal'i arka planda bekle
(
  echo "↩  $SORU" >&2
  read -r -t "$TIMEOUT" LINE 2>/dev/null
  if [ -n "$LINE" ] && [ ! -s "$TMPFILE" ]; then
    echo "$LINE" > "$TMPFILE"
  fi
) &
TERM_PID=$!

echo "$TG_PID $TERM_PID" > "$PIDFILE"

# İkisini de bekle, hangisi doldurarsa çık
DEADLINE=$(($(date +%s) + TIMEOUT))
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  if [ -s "$TMPFILE" ]; then
    # Diğerini durdur
    kill $TG_PID $TERM_PID 2>/dev/null
    cat "$TMPFILE"
    rm -f "$TMPFILE" "$PIDFILE"
    exit 0
  fi
  sleep 0.5
done

kill $TG_PID $TERM_PID 2>/dev/null
rm -f "$TMPFILE" "$PIDFILE"
exit 1
