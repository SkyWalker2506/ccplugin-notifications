---
name: alert-toggle
description: "Notification sesini aç/kapat. Triggers: alert toggle, ses kapat, mute, unmute, sound toggle, sessiz mod, bildirim sesi"
---

# /alert-toggle

Notification sesini toggle eder.

## Akış
1. `~/.claude/notifications-mute` dosyası var mı kontrol et
2. Varsa → sil → "🔊 Ses açıldı" bildir (Telegram'a da gönder)
3. Yoksa → oluştur → "🔇 Ses kapatıldı" bildir (Telegram'a da gönder)

## Uygulama

```bash
MUTE_FILE="$HOME/.claude/notifications-mute"

if [ -f "$MUTE_FILE" ]; then
  rm "$MUTE_FILE"
  bash notify.sh "🔊 Notification sesi açıldı" "🔊"
  echo "🔊 Ses açıldı"
else
  touch "$MUTE_FILE"
  bash notify.sh "🔇 Notification sesi kapatıldı (sessiz mod)" "🔇"
  echo "🔇 Ses kapatıldı"
fi
```
