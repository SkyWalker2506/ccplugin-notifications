# ccplugin-notifications

Multi-channel notifications for [Claude Code](https://claude.ai/claude-code).

**Channels:** Telegram · macOS native · Sound (pause/resume music)  
**Triggers:** Build error · AI question · Task done (DevFocus)

Part of the [claude-config](https://github.com/SkyWalker2506/claude-config) Multi-Agent OS — works standalone too.

## Install

```bash
# With claude-config (recommended)
claude plugin install notifications@musabkara-claude-marketplace

# Standalone
git clone https://github.com/SkyWalker2506/ccplugin-notifications
cd ccplugin-notifications && bash install.sh
```

## Usage

```bash
# Single entry point
bash notify.sh --message "Deploy complete" --channel all
bash notify.sh --channel telegram --message "Backup done" --emoji "💾"
bash notify.sh --event build-error --message "flutter analyze failed"
bash notify.sh --event ai-question --message "Approve schema migration?"
bash notify.sh --event task-done --message "Feature shipped"
```

## Commands

| Command | Description |
|---------|-------------|
| `/sound-toggle` | Toggle notification sound on/off (`~/.claude/notifications-mute` flag) |

## Channels

| Channel | Description |
|---------|-------------|
| `telegram` | Telegram message (requires `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID`) |
| `macos` | macOS native notification popup |
| `sound` | Alert sound via afplay (macOS) |
| `all` | sound + macos + telegram |

## DevFocus Triggers

| Event | Behavior |
|-------|----------|
| `build-error` | Pause music → alert sound → notify all |
| `ai-question` | Pause music → bring terminal to front → notify |
| `task-done` | Resume music → success notification |

## Setup — Telegram

Add to `~/.claude/secrets/secrets.env`:
```bash
TELEGRAM_BOT_TOKEN=<from @BotFather>
TELEGRAM_CHAT_ID=<from @userinfobot>
```

Telegram is optional — other channels work without it.

## Relation to ccplugin-telegram

`ccplugin-telegram` focuses on **bidirectional control** — run Claude from your phone.  
`ccplugin-notifications` focuses on **outbound notifications** — Claude notifies you.

They share the same Telegram credentials and can run simultaneously.

## Related

- [claude-config](https://github.com/SkyWalker2506/claude-config) — Multi-Agent OS
- [ccplugin-telegram](https://github.com/SkyWalker2506/ccplugin-telegram) — Control Claude via Telegram
- [claude-marketplace](https://github.com/SkyWalker2506/claude-marketplace) — Browse & install all 18 plugins
- [ClaudeHQ](https://github.com/SkyWalker2506/ClaudeHQ) — Claude ecosystem HQ
