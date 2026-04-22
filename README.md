# ccplugin-notifications

macOS notifications and DevFocus sound integration for [Claude Code](https://claude.ai/claude-code).

**Channels:** macOS native · Sound (pause/resume music)  
**Triggers:** Build error · AI question · Task done (DevFocus)  
**Platform:** macOS only

> **Note:** Telegram support is provided by [ccplugin-telegram](https://github.com/SkyWalker2506/ccplugin-telegram), not this plugin.

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
bash notify.sh --channel macos --message "Backup done"
bash notify.sh --channel sound --message "Alert"
bash notify.sh --event build-error --message "flutter analyze failed"
bash notify.sh --event ai-question --message "Approve schema migration?"
bash notify.sh --event task-done --message "Feature shipped"

# View notification history
bash notify.sh --list

# Test all channels
bash notify.sh --test

# Custom sound
bash notify.sh --message "Done" --sound Ping
```

## Commands

| Command | Description |
|---------|-------------|
| `/alert-toggle` | Toggle notification sound on/off |
| `/alert-toggle-on` | Enable notification sound |
| `/alert-toggle-off` | Disable notification sound (mute) |
| `/notify` | Send a manual notification |

## Channels

| Channel | Description |
|---------|-------------|
| `macos` | macOS native notification popup |
| `sound` | Alert sound via afplay + pause/resume Spotify/Music |
| `all` | sound + macos (default) |
| `telegram` | **Not supported** — requires [ccplugin-telegram](https://github.com/SkyWalker2506/ccplugin-telegram) |

## DevFocus Triggers

| Event | Behavior |
|-------|----------|
| `build-error` | Pause music + alert sound + macOS notification |
| `ai-question` | Pause music + alert sound + macOS notification + bring Terminal to front |
| `task-done` | Resume music + success sound + macOS notification |

## Configuration

Create `~/.claude/notifications-config.json` to customize:

```json
{
  "sound": "Ping"
}
```

Available sounds: `Glass` (default), `Ping`, `Sosumi`, `Basso`, `Purr`, `Submarine`, etc.

Mute all notifications: `touch ~/.claude/notifications-mute`  
Unmute: `rm ~/.claude/notifications-mute`

## Notification History

All notifications are logged to `~/.claude/notification-history.log`.  
View recent notifications: `bash notify.sh --list`

## Relation to ccplugin-telegram

`ccplugin-telegram` focuses on **bidirectional control** — run Claude from your phone and receive Telegram notifications.  
`ccplugin-notifications` focuses on **macOS-native outbound notifications** — sound and desktop alerts.

They complement each other and can run simultaneously.

## Related

- [claude-config](https://github.com/SkyWalker2506/claude-config) — Multi-Agent OS
- [ccplugin-telegram](https://github.com/SkyWalker2506/ccplugin-telegram) — Control Claude via Telegram
- [claude-marketplace](https://github.com/SkyWalker2506/claude-marketplace) — Browse & install all plugins
- [ClaudeHQ](https://github.com/SkyWalker2506/ClaudeHQ) — Claude ecosystem HQ
