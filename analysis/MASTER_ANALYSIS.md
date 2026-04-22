# MASTER ANALYSIS — ccplugin-notifications

**Date:** 2026-04-22  
**Forge Run:** 1 of 3  
**Analyst:** Jarvis | Sonnet 4.6

---

## 1. Project Overview

`ccplugin-notifications` is a multi-channel notification plugin for Claude Code. It sends notifications via macOS native notifications and sound (Spotify/Music pause/resume). Telegram is explicitly delegated to `ccplugin-telegram`.

---

## 2. Current Architecture

```
notify.sh               — Main entry point (dispatch by channel/event)
channels/
  macos.sh              — osascript native notification
  sound.sh              — afplay alert + Spotify/Music pause/resume
  telegram.sh           — Stub: redirects to ccplugin-telegram
triggers/
  ai-question.sh        — Pause music + alert + notify (waiting for input)
  build-error.sh        — Pause music + alert + notify (error)
  task-done.sh          — Resume music + alert + notify (done)
commands/
  alert-toggle.md       — Toggle mute flag
  alert-toggle-on.md    — Enable notifications
  alert-toggle-off.md   — Disable notifications
  notify.md             — Manual notification command
skills/
  notify/SKILL.md       — Auto-trigger skill
config/
  telegram-*.{sh,py}    — Telegram interaction helpers (ask/poll/wait)
```

---

## 3. Strengths

- Clean channel abstraction — easy to add new channels
- DevFocus concept (pause/resume music) is unique and useful
- Single entry point (notify.sh) with clear CLI interface
- Mute flag (`~/.claude/notifications-mute`) is simple and effective
- Three trigger events cover the main developer workflow states

---

## 4. Weaknesses & Gaps

### Critical
1. **telegram.sh is a stub** — the README says `--channel all` includes telegram, but the channel script just prints an error. The README is misleading.
2. **config/telegram-*.{sh,py} are orphaned** — these files exist but are never called from notify.sh or triggers
3. **build-error.sh calls telegram.sh** — which fails silently, creating false expectations

### Medium
4. **No retry logic** — if macOS notification fails (e.g., permissions), no fallback
5. **osascript not verified before use** — non-macOS systems will silently fail
6. **sound.sh hardcodes Glass.aiff** — no user config for sound choice
7. **No notification history/log** — can't review what was notified when
8. **notify.md command** — describes `--buttons` param but it's silently ignored (marked as TODO)
9. **skills/notify/SKILL.md** — references undocumented trigger patterns

### Low
10. **README says "Commands: /sound-toggle"** but actual command files are alert-toggle-{on,off,toggle}.md
11. **No tests** — shell scripts untested
12. **afplay path not validated** — macOS-only, no Linux/Windows path

---

## 5. Opportunities

| Opportunity | Category | Priority | Effort |
|-------------|----------|----------|--------|
| Fix README: clarify telegram requires ccplugin-telegram | Docs | High | Quick |
| Remove or wire up orphaned telegram config files | Cleanup | High | Quick |
| Add notification log (`~/.claude/notification-history.log`) | Feature | Medium | Quick |
| Add configurable sound choice to `~/.claude/notifications-config.json` | Feature | Medium | Quick |
| Add `--sound` param to notify.sh | UX | Medium | Quick |
| Add platform guard (exit gracefully on non-macOS) | Bug Fix | Medium | Quick |
| Wire `--buttons` param or remove from docs | Cleanup | Medium | Quick |
| Add `notify --list` to show notification history | Feature | Low | Quick |

---

## 6. Dependency Analysis

- **Depends on:** macOS (`osascript`, `afplay`), Spotify/Apple Music (optional), Telegram (optional)
- **Used by:** Claude Code hooks (PostToolUse, Stop, etc.)
- **Conflicts:** telegram.sh stub misleads users expecting full multi-channel

---

## 7. Risk Assessment

- **Low risk** project overall
- Main risk: README/code mismatch erodes trust in the plugin
- No secrets in this plugin (telegram credentials in ccplugin-telegram)

---

## 8. Recommended Sprint Focus

**Sprint 1:** Fix README + remove misleading telegram stub + fix command name mismatch  
**Sprint 2:** Add notification log + configurable sound + platform guard  
**Sprint 3:** Wire up orphaned config files OR formally deprecate them + `notify --list`
