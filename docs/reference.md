# Skills & Agents Reference

All workflow capabilities are implemented as skills in `skills/`.

## Planning Pipeline

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `/product-review` | Product-taste review: EXPAND / HOLD / REDUCE modes | Before `/spec` for greenfield features, or standalone |
| `/spec` | Research, plan, decompose into tasks | New idea, feature description, or goal |
| `/spec --deepen` | Enhance plan with parallel research agents | Existing plan needs more depth |

## Execution

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `/orient` | Build context, identify parallel work | Session start |
| `/start-task <id>` | Claim task, gather context, define criteria | Beginning a task |
| `/finish-task <id>` | Tests, commit, PR, cleanup, close | Task complete |
| `/dispatch` | Spawn Agent Teams teammates (with isolation verification) | Multiple ready tasks |
| `/auto-run` | Autonomous dispatch-reconcile loop | Batch processing, overnight runs |
| `/milestone-review` | Iterative review-fix loop for branch changes | After milestone tasks complete, or manually |
| `/summarize-session <id>` | Progress summary (read-only) | Mid-session checkpoint |
| `/reconcile-summary` | Sync beads with implementation reality | After worker completes |

## Quality

| Skill | Purpose | Triggers |
|-------|---------|----------|
| `/multi-review` | Parallel code review with specialized agents | "thorough review", PR review, explicit |

## Utility

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `/retro` | Git-based engineering retrospective with trend tracking | Weekly review, shipping metrics, work patterns |
| `/humanizer` | Remove AI writing patterns | Text sounds like AI slop |
| `/claudemd-audit` | Audit CLAUDE.md for bloat, staleness, architecture | Reviewing CLAUDE.md quality, new project setup |
| Playwright MCP | Browser automation for frontend verification | `/finish-task`, `/multi-review`, `/milestone-review` |

## Discipline

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `/verify` | Evidence before claims, anti-sycophancy | Cross-referenced by other skills; invoke when making completion claims |
| `/debug` | Systematic debugging methodology | Bug, test failure, unexpected behavior |
| `/writing-skills` | Skill authoring guidance | Creating or revising a skill definition |

## Research Agents

Available in `/orient` (Phase 1.5) and `/start-task` (Step 5.5) for complex tasks:

| Agent | Purpose |
|-------|---------|
| `repo-research-analyst` | Map architecture, conventions |
| `git-history-analyzer` | Historical context, contributors |
| `framework-docs-researcher` | Library docs, deprecation checks |
| `best-practices-researcher` | Industry patterns, recommendations |

## Review Agents

**Review** (`/multi-review`): `code-simplicity-reviewer`, `security-sentinel`, `api-security-reviewer`, `performance-oracle`, `pattern-recognition-specialist`, `architecture-strategist`, `agent-native-reviewer`, `data-integrity-guardian`, `data-migration-expert`. Framework-specific (`nextjs-reviewer`, `tailwind-reviewer`, `python-backend-reviewer`) auto-detect from changed files.

**Workflow**: `spec-flow-analyzer` — analyze specs for dependencies, gaps, feasibility.

## Project Configuration

Optional `.claude/review.json` configures risk tiers and reviewer overrides for `/multi-review` and `/dispatch`. See `docs/examples/review-fullstack.json` for examples.
