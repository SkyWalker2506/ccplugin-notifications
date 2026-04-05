---
name: alert-toggle-off
description: "Notification sesini kapat (mute). Triggers: alert off, ses kapat, mute, sessiz mod, bildirimleri kapat"
---

# /alert-toggle-off

Notification sesini kapatır (mute).

## Uygulama

```bash
MUTE_FILE="$HOME/.claude/notifications-mute"
touch "$MUTE_FILE"
bash notify.sh "🔇 Notification sesi kapatıldı (sessiz mod)" "🔇"
echo "🔇 Ses kapatıldı"
```
