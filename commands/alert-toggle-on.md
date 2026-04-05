---
name: alert-toggle-on
description: "Notification sesini aç (unmute). Triggers: alert on, ses aç, unmute, bildirimleri aç"
---

# /alert-toggle-on

Notification sesini açar (unmute).

## Uygulama

```bash
MUTE_FILE="$HOME/.claude/notifications-mute"
rm -f "$MUTE_FILE"
bash notify.sh "🔊 Notification sesi açıldı" "🔊"
echo "🔊 Ses açıldı"
```
