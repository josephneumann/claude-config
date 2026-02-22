# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-02-22

### Added

- **`/verify` skill** — Centralized verification discipline with Iron Law, anti-rationalization table, red flags, and anti-sycophancy guidance. Cross-referenced from `/finish-task`, `/start-task`, `/reconcile-summary`, and `/multi-review`. Inspired by [obra/superpowers](https://github.com/obra/superpowers).
- **`/debug` skill** — Systematic four-phase debugging methodology with three-strikes rule. Adapted from superpowers.
- **`/writing-skills` skill** — Meta-skill for authoring effective skills. CSO principles, word count targets, tone guidance from `/humanizer`, persuasion principles from Cialdini research.
- **Principle 11: "Evaluate, don't agree"** — Anti-sycophancy guidance added to CLAUDE.md philosophy.
- **Spirit vs Letter preemption** — Added to CLAUDE.md philosophy section.
- **Distrust verification in `/reconcile-summary`** — Cross-references PR/CI evidence before trusting session summary claims.

### Changed

- **Combined `/brainstorm`, `/plan`, and `/deepen-plan` into `/spec`** — Single skill replaces three. Interactive refinement is Phase 0; research enhancement is `--deepen` flag. Eliminates naming conflict with built-in plan mode.
- **Removed "Never Use Built-in Plan Mode" critical rule** — No longer needed with `/spec` naming.
- **Removed `/last30days` skill** — Was a nested git repo (`mvanhorn/last30days-skill`) invisible to parent tracking. Removed entirely.
- **Added `allowed-tools` to `/compound-docs` and `/humanizer`** — Only 2 skills missing this frontmatter field.
- **Added `docs/plans/.gitkeep`** — Ensures `/spec` output directory exists in fresh clones.
- **CSO audit of skill descriptions** — Rewrote 5 skill descriptions to contain triggering conditions only (not workflow summaries). Prevents agents from shortcutting full skill content.
- **CLAUDE.md compressed** — Moved auto-run docs, divergence handling, and worktree details into individual skills. Target <1,200 words (from ~1,931).
- **Cross-references to `/verify`** added in `/finish-task` (before quality gates, in auto-fix), `/start-task` (acceptance criteria), `/multi-review` (auto-fix evaluation).

## [1.1.0] - 2026-02-21

### Changed

- **Renamed `risk-tiers.json` to `review.json`** — Clearer name. Both filenames supported for backward compatibility.
- **Framework reviewers now auto-detect** — `nextjs-reviewer`, `tailwind-reviewer`, and `python-backend-reviewer` activate automatically when changed files match their patterns. No `frameworks` array needed.
- **New `reviewers` config object** — `reviewers.exclude` suppresses false positives, `reviewers.include` forces always-on reviewers. Replaces the `frameworks` array.
- **Schema version bumped to 2** — v1 configs with `frameworks` array still work (deprecated).

## [1.0.0] - 2026-02-21

### Added

- **13 workflow skills**: `/brainstorm`, `/plan`, `/deepen-plan`, `/orient`, `/start-task`, `/finish-task`, `/dispatch`, `/auto-run`, `/reconcile-summary`, `/summarize-session`, `/multi-review`, `/compound`, `/compound-docs`
- **21 specialized agents**: 5 research, 11 review (including framework-specific for Next.js, Tailwind, Python), 1 workflow
- **5 quality gate hooks**: guard-main-branch, worktree-setup, teammate-idle-guard, task-completed-guard, reconcile-reminder
- **Risk tier configuration**: Per-project `.claude/risk-tiers.json` for risk-based review depth and smart model selection
- **Autonomous orchestration**: `/auto-run` with checkpoint/restart support and `auto-run.sh` wrapper for unattended multi-hour runs
- **Compound engineering**: Auto-compound in `/finish-task` and interactive `/compound` for capturing solutions
- **Plugin marketplace support**: Discoverable via Claude Code's native plugin system
- **MIT license**

[2.0.0]: https://github.com/josephneumann/claude-corps/releases/tag/v2.0.0
[1.1.0]: https://github.com/josephneumann/claude-corps/releases/tag/v1.1.0
[1.0.0]: https://github.com/josephneumann/claude-corps/releases/tag/v1.0.0
