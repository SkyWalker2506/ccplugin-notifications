---
description: Send a notification via Telegram, macOS, or sound
argument-hint: [message] [--channel telegram|macos|sound|all]
allowed-tools: [Bash]
---

# Notify

Send a notification through configured channels.

## Usage

```
/notify "Deploy complete"
/notify "Build failed" --channel telegram
/notify --event ai-question --message "Approve schema migration?"
```

## What this does

Run `bash ~/.claude/skills/notifications/notify.sh` with the provided arguments.

- No channel specified → all channels (sound + macOS + Telegram if configured)
- `--event build-error` → pause music, alert sound, macOS + Telegram notification
- `--event ai-question` → pause music, bring terminal to front, notify
- `--event task-done` → resume music, success notification

If `TELEGRAM_BOT_TOKEN` is not set, Telegram channel is skipped silently.
