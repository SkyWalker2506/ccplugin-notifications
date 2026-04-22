# SPRINT PLAN — ccplugin-notifications

**Date:** 2026-04-22  
**Based on:** MASTER_ANALYSIS.md  
**Forge Runs:** 3 × 3 sprints

---

## Sprint 1 — Accuracy & Trust Fixes

**Goal:** Fix misleading docs and code mismatches that erode user trust.

| Task | Description | Effort |
|------|-------------|--------|
| S1-T1 | Fix README: remove mention of telegram from `--channel all`, add note that telegram requires ccplugin-telegram | Quick |
| S1-T2 | Fix `notify.sh`: `--channel all` should only call sound + macos (not attempt telegram stub) | Quick |
| S1-T3 | Fix README command name: change `/sound-toggle` to `/alert-toggle` to match actual command files | Quick |
| S1-T4 | Add platform guard to `macos.sh` and `sound.sh` — exit 0 gracefully on non-macOS | Quick |
| S1-T5 | Clean up orphaned `config/telegram-*.{sh,py}` — either document them as standalone tools or remove | Quick |

---

## Sprint 2 — Logging & Configuration

**Goal:** Make notifications configurable and inspectable.

| Task | Description | Effort |
|------|-------------|--------|
| S2-T1 | Add notification log: append to `~/.claude/notification-history.log` in `notify.sh` | Quick |
| S2-T2 | Add `notify --list` flag to show last 20 notification history entries | Quick |
| S2-T3 | Add configurable sound: read `NOTIFY_SOUND` from `~/.claude/notifications-config.json` | Quick |
| S2-T4 | Add `--sound <name>` param to `notify.sh` with fallback to config | Quick |
| S2-T5 | Document `~/.claude/notifications-config.json` schema in README | Quick |

---

## Sprint 3 — Robustness & UX

**Goal:** Make the plugin resilient to failures and more useful.

| Task | Description | Effort |
|------|-------------|--------|
| S3-T1 | Add retry logic to `macos.sh` — attempt notification 2x if first fails | Quick |
| S3-T2 | Wire or remove `--buttons` param from `notify.md` command spec | Quick |
| S3-T3 | Update `skills/notify/SKILL.md` with actual trigger patterns from command spec | Quick |
| S3-T4 | Add `notify --test` flag to test all configured channels | Quick |
| S3-T5 | Add `notify --mute-until <minutes>` for timed muting | Medium |

---

## Task Priority Matrix

| Priority | Tasks |
|----------|-------|
| P0 (Critical) | S1-T1, S1-T2, S1-T3 |
| P1 (High) | S1-T4, S1-T5, S2-T1, S2-T2 |
| P2 (Medium) | S2-T3, S2-T4, S2-T5, S3-T2, S3-T3 |
| P3 (Low) | S3-T1, S3-T4, S3-T5 |

---

## Skip Criteria (>2hr tasks)

- No tasks exceed 2hr. S3-T5 is the most complex but still under 1hr.
