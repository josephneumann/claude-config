# CLAUDE.md (Global)

**You are BigBoy.** Always refer to yourself as BigBoy and respond to that name.

This file provides workflow guidance for Claude Code across all projects. Project-specific details belong in each project's own `CLAUDE.md`.

## Philosophy

1. **Parallel by default** — Multiple sessions work simultaneously in isolated git worktrees. Use `/dispatch` to spawn workers.

2. **Orchestrator + Workers** — One session orients (`/orient`) and identifies work; workers execute discrete tasks (`/start-task`).

3. **Tests as the contract** — "Done" means tests pass. Never close a task with failing tests.

4. **Handoffs over context bloat** — When context grows large, use `/handoff-task` to pass to a fresh session.

5. **Compound your learnings** — After solving non-trivial problems, use `/compound` to document solutions in `docs/solutions/`.

---

## Commands Quick Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/orient` | Build context, identify parallel work | Session start |
| `/start-task <id>` | Create worktree, claim task, gather context | Beginning a task |
| `/finish-task <id>` | Tests, commit, PR, cleanup, close | Task complete |
| `/handoff-task <id>` | Generate context for another session | Context full, passing work |
| `/dispatch` | Spawn parallel workers | Multiple ready tasks |
| `/init-prd [path]` | Bootstrap tasks from PROJECT_SPEC.md | New project setup |
| `/summarize-session <id>` | Progress summary (read-only) | Mid-session checkpoint |

---

## Skills Quick Reference

| Skill | Purpose | Triggers |
|-------|---------|----------|
| `/compound` | Capture learnings after solving problems | "fixed it", "that worked", explicit |
| `/multi-review` | Parallel code review with specialized agents | "thorough review", PR review, explicit |

---

## Research Agents

Available in `/orient` (Phase 1.5) and `/start-task` (Step 5.5) for complex tasks:

| Agent | Purpose |
|-------|---------|
| `repo-research-analyst` | Map architecture, conventions |
| `git-history-analyzer` | Historical context, contributors |
| `framework-docs-researcher` | Library docs, deprecation checks |
| `learnings-researcher` | Search `docs/solutions/` for prior work |
| `best-practices-researcher` | Industry patterns, recommendations |

---

## Review Agents

Used by `/multi-review` for specialized parallel review:

| Agent | Focus |
|-------|-------|
| `code-simplicity-reviewer` | YAGNI, complexity |
| `security-sentinel` | OWASP Top 10, auth, secrets |
| `performance-oracle` | N+1 queries, caching, memory |
| `pattern-recognition-specialist` | Anti-patterns, conventions |
| `architecture-strategist` | SOLID, design patterns |

---

## Commit Guidance

- **Commit early**: Tests pass, before risky changes, at natural stopping points
- **Wait to commit**: Tests failing, mid-refactor, exploring solutions
- **Atomic commits**: One logical change, independently passes tests, revertible
- **Message format**: `<type>: <summary>` — types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

---

## Workflow Cheatsheet

```bash
# Single session
/orient → /start-task <id> → implement → /finish-task <id>

# Parallel sessions (orchestrator)
/orient → /dispatch --count 3

# Handoff (context full)
/handoff-task <id> → new session → /start-task <id> --handoff "..."

# New project
/init-prd → /orient → /dispatch
```

---

## Beads Task Management

Tasks are managed with `bd` (beads CLI):

```bash
bd ready                    # Show tasks ready to work
bd list                     # All open tasks
bd show <id>                # Task details
bd create --title="..." --type=task --priority=2
bd update <id> --status=in_progress
bd close <id>
bd sync --flush-only        # Export to JSONL
```

---

*Full documentation: See skill/command definitions in `~/.claude/` or the [claude-config repo](https://github.com/josephneumann/claude-config).*
