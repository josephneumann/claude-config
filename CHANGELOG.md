# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-02-22

Verification discipline. Simplified planning. Leaner docs.

### Added

- **`/verify` skill** — Evidence before claims. Cross-referenced from `/finish-task`, `/start-task`, `/reconcile-summary`, and `/multi-review` so verification happens at every decision point. Inspired by [obra/superpowers](https://github.com/obra/superpowers).
- **`/debug` skill** — Four-phase systematic debugging with a three-strikes rule: if three consecutive fix attempts fail, your assumptions are wrong. Stop and re-examine. Adapted from superpowers.
- **`/writing-skills` skill** — Meta-skill for authoring skills. CSO description design, word count targets, anti-rationalization patterns, persuasion principles from Cialdini research.
- **Principle 11: "Evaluate, don't agree"** — No performative agreement. Verify claims against evidence. YAGNI applies to review suggestions too.
- **Spirit vs Letter preemption** — Added to CLAUDE.md philosophy section.
- **Distrust verification in `/reconcile-summary`** — Cross-references PR/CI evidence before trusting session summary claims.

### Changed

- **`/spec` replaces `/brainstorm`, `/plan`, and `/deepen-plan`** — One skill, two modes. `/spec` runs interactive refinement, research, planning, and task decomposition. `/spec --deepen` enhances an existing plan with parallel research agents. The three-skill pipeline was conceptually one workflow — now it's one command. Also eliminates the "Never Use Built-in Plan Mode" critical rule that existed solely because `/plan` collided with Claude Code's built-in plan mode.
- **CLAUDE.md compressed from ~1,931 to ~1,200 words** — Auto-run docs, divergence handling, and worktree details moved into the skills that use them. The global config is a routing table, not an encyclopedia.
- **CSO audit of 5 skill descriptions** — Rewrote descriptions to contain triggering conditions only (not workflow summaries). Prevents agents from shortcutting full skill content.
- **Cross-references to `/verify`** added in `/finish-task` (before quality gates, in auto-fix), `/start-task` (acceptance criteria), `/multi-review` (auto-fix evaluation).
- **Added `allowed-tools` to `/compound-docs` and `/humanizer`** — Only 2 skills were missing this frontmatter field. All 15 now consistent.
- **Added `docs/plans/.gitkeep`** — Ensures `/spec` output directory exists in fresh clones.

### Removed

- **`/brainstorm`**, **`/plan`**, **`/deepen-plan`** — Replaced by `/spec` and `/spec --deepen`.
- **`/last30days`** — Was a nested git repo from an external project, invisible to parent git tracking. Removed rather than fixed.
- **"Never Use Built-in Plan Mode" critical rule** — No longer needed with `/spec` naming.

### Upgrading from v1.x

If you reference `/brainstorm`, `/plan`, or `/deepen-plan` in any scripts or docs, replace with `/spec` and `/spec --deepen`.

### By the numbers

- 15 skills (was 13 at v1.0.0 — added 4, removed 4)
- 21 specialized agents (unchanged)
- 25 files changed, +646 / -1,336 lines

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
