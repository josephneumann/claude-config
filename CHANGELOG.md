# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-02-21

### Changed

- **Renamed `risk-tiers.json` to `review.json`** — Clearer name. Both filenames supported for backward compatibility.
- **Framework reviewers now auto-detect** — `nextjs-reviewer`, `tailwind-reviewer`, and `python-backend-reviewer` activate automatically when changed files match their patterns. No `frameworks` array needed.
- **New `reviewers` config object** — `reviewers.exclude` suppresses false positives, `reviewers.include` forces always-on reviewers. Replaces the `frameworks` array.
- **Schema version bumped to 2** — v1 configs with `frameworks` array still work (deprecated).

## [1.0.0] - 2026-02-21

### Added

- **14 workflow skills**: `/brainstorm`, `/plan`, `/deepen-plan`, `/orient`, `/start-task`, `/finish-task`, `/dispatch`, `/auto-run`, `/reconcile-summary`, `/summarize-session`, `/multi-review`, `/compound`, `/compound-docs`
- **21 specialized agents**: 5 research, 11 review (including framework-specific for Next.js, Tailwind, Python), 1 workflow
- **5 quality gate hooks**: guard-main-branch, worktree-setup, teammate-idle-guard, task-completed-guard, reconcile-reminder
- **Risk tier configuration**: Per-project `.claude/risk-tiers.json` for risk-based review depth and smart model selection
- **Autonomous orchestration**: `/auto-run` with checkpoint/restart support and `auto-run.sh` wrapper for unattended multi-hour runs
- **Compound engineering**: Auto-compound in `/finish-task` and interactive `/compound` for capturing solutions
- **Plugin marketplace support**: Discoverable via Claude Code's native plugin system
- **MIT license**

[1.0.0]: https://github.com/josephneumann/claude-corps/releases/tag/v1.0.0
