# Changelog

All notable changes to this project will be documented in this file.

## [2.1.0] - 2026-03-08

### Breaking Changes

- **Worktree isolation replaced with branch isolation for Agent Teams** — `isolation: "worktree"` on the Agent tool is silently ignored when `team_name` is set (upstream issues #23669, #24294, #27749, #30703). Workers spawned via `/dispatch` now create task-specific branches instead of worktrees. Step 4.5 in `/dispatch` verifies branch isolation instead of worktree cwd. Worktree infrastructure is retained for manual `claude --worktree` sessions.

### Changed

- **`/dispatch`** — Removed `isolation: "worktree"` from teammate spawn calls. Spawn prompts instruct workers to create a task-specific branch immediately. Step 4.5 replaced: checks that each worker is on a task branch (not main/milestone), with warning + retry before shutdown.
- **`/auto-run`** — Checkpoint schema renamed `worktree_failures` → `branch_isolation_failures` and `total_worktree_failures` → `total_branch_isolation_failures`. Removed `isolation: "worktree"` from milestone review worker spawn. Final report shows "Branch Isolation Failures" instead of "Worktree Failures".
- **`/start-task`** — Step 7 replaced: verifies worker is on a task branch (creates one if on main) instead of checking worktree isolation.
- **`/finish-task`** — Updated terminology from "worktree" to "task branch" in verification and cleanup steps. Kept `git worktree list` for path resolution (valid git usage).
- **`/orient`** — Updated terminology in investigation indicators and orientation report.
- **`CLAUDE.md`** — Principle 1 updated: "isolated branches" instead of "isolated git worktrees".
- **`README.md`, `llms.txt`** — All dispatch/isolation references updated from worktree to branch terminology.
- **`plugin.json`, `marketplace.json`** — Updated descriptions and keywords.
- **`hooks/guard-main-branch.sh`** — Updated error messages to reference task branches.

### Not Changed (intentional)

- `hooks/worktree-setup.sh` — Still useful for manual `claude --worktree` sessions
- `hooks/hooks.json` — WorktreeCreate hook stays (fires for manual worktrees)
- `git worktree list` commands in skills — Used for path resolution, not isolation
- `.gitignore` `.claude/worktrees/` entry — Directory still exists for manual use

## [2.0.3] - 2026-02-28

### Removed

- **Compound engineering system** — Removed `/compound`, `/compound-docs` skills, `learnings-researcher` agent, and all `docs/solutions/` references. The built-in auto-memory system in Claude Code handles persistent learnings better without requiring custom document schemas, file conventions, or search agents. Principle 9 updated from "Compound your learnings" to "Save what you learn" via auto-memory.

### Changed

- **`code-simplicity-reviewer` enhanced with anti-over-simplification guardrails** — Added "Maintain Balance" (item 7) and "Respect Project Standards" (item 8) review criteria, inspired by Anthropic's official code-simplifier agent. Softened opening tone from "ruthlessly simplify" to "simplify code while maintaining clarity." The reviewer now warns against nested ternaries, dense one-liners, removing helpful abstractions, and combining too many concerns. It also reads CLAUDE.md for project conventions before reviewing.
- **`/finish-task` auto-compound replaced with auto-memory** — Step 14.5 now saves non-obvious insights to auto-memory instead of writing structured documents to `docs/solutions/`.
- **`/debug` post-debug hook updated** — Points to auto-memory instead of `/compound`.
- **`/spec` and `/start-task` research agents** — Removed `learnings-researcher` from parallel research agent lists.
- **README and CLAUDE.md** — Removed compound engineering references, updated skill tables, simplified project structure docs.

### By the numbers

- 13 skills (was 15 — removed `/compound` and `/compound-docs`)
- 20 specialized agents (was 21 — removed `learnings-researcher`)
- 14 files changed, +40 / -890 lines

## [2.0.2] - 2026-02-23

### Fixed

- **Worktree isolation verification** — Workers spawned with `isolation: "worktree"` could silently fail to create git worktrees, falling back to the main repo and causing branch conflicts, file collisions, and crashes. The orchestrator had no mechanism to detect this. Fix: `/dispatch` now includes Step 4.5 which verifies isolation after spawning by checking team config `cwd` values and corroborating with `git worktree list`. Non-isolated workers are shut down immediately, tasks unassigned for retry.
- **Auto-run worktree failure tracking** — `/auto-run` checkpoint now tracks `worktree_failures` with a circuit breaker: same task failing isolation twice is moved to `failed` and flagged for human attention. Final report surfaces `Worktree Failures` count.

## [2.0.1] - 2026-02-22

### Fixed

- **Plan-mode dispatch deadlock** — Teammates spawned with `mode: "plan"` would call `ExitPlanMode`, go idle, and wait indefinitely because the orchestrator lacked clear instructions on how to respond. Fix: (a) teammate now sends an explicit DM to the lead immediately after `ExitPlanMode` with the `request_id`, (b) post-dispatch summary includes `request_id` requirement and CRITICAL urgency marker, (c) orchestrator is reminded to handle all plan approvals before considering dispatch complete.
- **`/spec` skipping decomposition prompt** — Phase 3 was labeled "Optional" and used plain dialogue that could be silently skipped. Fix: always uses `AskUserQuestion` when `bd` is available, silently skips only when `bd` is genuinely unavailable. Phase 4 menu now conditionally hides dispatch/solo options when no tasks exist and offers "Decompose now" as an alternative.
- **Deepen mode showing dispatch without tasks** — Step 10 menu offered `/dispatch` and `/start-task` even when no beads tasks existed. Fix: checks `bd list` and conditionally shows "Decompose into tasks" instead.

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

[2.1.0]: https://github.com/josephneumann/claude-corps/releases/tag/v2.1.0
[2.0.3]: https://github.com/josephneumann/claude-corps/releases/tag/v2.0.3
[2.0.2]: https://github.com/josephneumann/claude-corps/releases/tag/v2.0.2
[2.0.1]: https://github.com/josephneumann/claude-corps/releases/tag/v2.0.1
[2.0.0]: https://github.com/josephneumann/claude-corps/releases/tag/v2.0.0
[1.1.0]: https://github.com/josephneumann/claude-corps/releases/tag/v1.1.0
[1.0.0]: https://github.com/josephneumann/claude-corps/releases/tag/v1.0.0
