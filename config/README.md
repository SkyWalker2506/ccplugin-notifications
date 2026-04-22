# config/ — Legacy Telegram Utilities

These files are **legacy utilities** from an earlier version of this plugin when Telegram was part of ccplugin-notifications. They are kept for reference but are **not actively used** by notify.sh.

## Files

| File | Description | Status |
|------|-------------|--------|
| `telegram-agent.py` | Python agent that polls Telegram for messages | Legacy — use ccplugin-telegram |
| `telegram-ask.sh` | Dual-input: accept response from Telegram OR terminal, whichever comes first | Legacy |
| `telegram-poll.sh` | Long-poll Telegram Bot API for incoming messages | Legacy |
| `telegram-wait.sh` | Wait for a Telegram response with timeout | Legacy |

## Why still here?

These scripts may be useful as standalone utilities for users who want to build custom Telegram interactions without the full ccplugin-telegram plugin. They are not wired into the main notification flow.

## For Telegram notifications

Install [ccplugin-telegram](https://github.com/SkyWalker2506/ccplugin-telegram):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SkyWalker2506/claude-marketplace/main/install.sh) telegram
```
