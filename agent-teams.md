# Agent Teams vs BEADS: Analysis & Integration Strategy

## TL;DR

Agent Teams replaces the **in-session orchestration layer** (dispatch, mp-spawn, signal/queue, handoffs). The **persistent project management layer** (beads tasks, reconciliation, knowledge compounding) stays. BEADS for planning and tracking, Agent Teams for execution.

---

## What Agent Teams Provides Natively

| Capability | How it works |
|---|---|
| **Team lead + teammates** | Lead coordinates, teammates are independent Claude sessions |
| **Shared task list** | Built-in task list with pending/in_progress/completed + dependencies |
| **Inter-agent messaging** | Mailbox system — teammates message each other directly |
| **Self-claiming** | Teammates pick up unassigned, unblocked tasks autonomously |
| **Delegate mode** | Lead restricted to coordination-only (no coding) |
| **Plan approval** | Teammates plan in read-only mode, lead approves before implementation |
| **Split-pane display** | tmux/iTerm2 integration — see all teammates at once |
| **Automatic dependency resolution** | When task X completes, tasks blocked by X auto-unblock |

## What Agent Teams Does NOT Provide

| Missing capability | Why it matters |
|---|---|
| **Persistent task management** | Teams are session-scoped. When the team ends, the task list is gone. No cross-session tracking. |
| **Git worktree isolation** | No mention of worktrees. Teammates all work in the same directory — high risk of file conflicts. Their docs literally warn "avoid same-file edits." |
| **Session summaries & reconciliation** | No structured handoff between sessions. No spec divergence tracking. |
| **Quality gates** | No "tests must pass before closing" enforcement |
| **Code review integration** | No `/multi-review` equivalent |
| **Knowledge compounding** | No `/compound` or `docs/solutions/` equivalent |
| **Rich task metadata** | No priorities, types (task/feature/bug/epic), or detailed descriptions beyond what the lead writes |
| **Cross-session continuity** | No session resumption for teammates. `/resume` doesn't restore them. |
| **Main branch protection** | No hook equivalent for preventing commits on main |

---

## How They Combine

| Phase | BEADS | Agent Teams |
|---|---|---|
| **Planning** | Plans and decomposes (`/plan` → `bd create`) | — |
| **Execution** | `/start-task` (worktrees), `/finish-task` (quality gates) | Spawns teammates, coordinates via messaging |
| **Completion** | `/reconcile-summary` syncs reality back to beads | Lead gets idle notifications on teammate completion |
| **Research** | — | Competing-hypothesis pattern: multiple investigators challenging each other |
| **Review** | — | Teammates debate findings in real time |
| **Learning** | `/compound` captures solutions in `docs/solutions/` | — |

## Known Constraints

1. **No session resumption** — teammates lost on resume
2. **One team per session** — can't manage multiple concurrent teams
3. **No nested teams** — teammates can't spawn sub-teams
4. **Lead is fixed** — can't promote teammates
5. **Split panes don't work in Ghostty** — use in-process mode with Shift+Up/Down
6. **No worktree isolation** — solved by teammates running `/start-task`

### Teammate Failure Handling

If a teammate goes idle without completing its task, the lead checks the task status. If incomplete, the lead can either message the teammate to retry, spawn a replacement, or pull the task back and handle it directly. Unfinished work stays tracked in beads regardless of what happens to the Agent Teams session.

---

## Implementation Plan: Agent Teams + BEADS Hybrid

Replace the dispatch/spawn/handoff plumbing with Agent Teams. Keep everything else from BEADS.

### How It Works

- BEADS owns task creation and tracking (`bd create`, `bd list`, `bd ready`)
- `/orient` still surveys the project and identifies parallel work
- `/dispatch` spawns Agent Teams teammates instead of calling `mp-spawn`
- Each teammate gets a spawn prompt with: task context from `bd show` + instruction to run `/start-task <task-id>` + acceptance criteria
- `/start-task` handles worktree creation, `.env` symlink, task claiming, and context gathering
- On completion, teammates write session summaries to `docs/session_summaries/`
- **Before ending the session**, the lead runs `/reconcile-summary` to sync all teammate work back to beads — Agent Teams state is session-scoped and lost on exit

Agent Teams also replaces subagent-based patterns for research, review, and debugging — teammates can challenge each other's findings in real time via inter-agent messaging.

### What Changes

| Component | Before | After |
|---|---|---|
| Worker spawning | `mp-spawn` (shell script, AppleScript/Ghostty) | Agent Teams native teammate spawning |
| Task handoff | Signal files + `.queue` + SessionStart hook | Spawn prompt with task context |
| Session handoff | `/handoff-task` generates copy-paste commands | Lead spawns replacement teammate and messages it directly |
| Coordination | Async file-based summaries | Real-time inter-agent messaging |
| Completion detection | Orchestrator polls for summaries | Lead gets automatic idle notifications |
| Parallel review | `/multi-review` subagents | Agent Teams teammates with debate |

### What Stays

- `bd` CLI — persistent task tracking across sessions
- `/orient` — project discovery and work identification
- `/start-task` — worktree creation, `.env` symlink, task claiming, context gathering (teammates run this directly)
- `/finish-task` — tests, commit, PR, code review, session summary, cleanup
- `/reconcile-summary` — cross-session reconciliation of spec vs. reality
- `/compound` — knowledge capture in `docs/solutions/`
- Session summaries — structured async handoff for cross-session work
- PreToolUse hooks — main branch protection

### What Gets Retired

| Artifact | Path | Why |
|---|---|---|
| `mp-spawn` | `bin/mp-spawn` | Replaced by native teammate spawning |
| Worker handoff hook | `hooks/load-worker-handoff.sh` | Signal/queue mechanism no longer needed |
| `/handoff-task` skill | `skills/handoff-task/SKILL.md` | Lead handles handoffs directly via messaging; no file-based handoff needed |
| Handoff queue | `docs/pending_handoffs/` | Context passed directly at spawn |

### What Gets Rewritten

| Artifact | Path | Change |
|---|---|---|
| `/dispatch` skill | `skills/dispatch/SKILL.md` | Rewrite to spawn Agent Teams teammates instead of calling `mp-spawn` |
| Global CLAUDE.md | `CLAUDE.md` | Remove "Automated Worker Handoff" section, remove `/handoff-task` references, update dispatch references |
| README | `README.md` | Remove mp-spawn docs, remove `/handoff-task` docs, update dispatch/prerequisites sections |
| `install.sh` | `install.sh` | Remove mp-spawn verification line |

### Implementation Order

1. **Enable Agent Teams** — Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` to `settings.json`
2. **Rewrite `/dispatch`** — New skill that spawns teammates with task context and `/start-task` instruction
3. **Delete retired artifacts** — `bin/mp-spawn`, `hooks/load-worker-handoff.sh`, `skills/handoff-task/`
4. **Update CLAUDE.md** — Remove "Automated Worker Handoff" section, remove `/handoff-task` from skills table, update workflow cheatsheet and philosophy references
5. **Update README.md** — Remove mp-spawn docs, `/handoff-task` docs, update dispatch description and prerequisites
6. **Update install.sh** — Remove mp-spawn verification line

Steps 1-2 must happen first (new dispatch must exist before old plumbing is removed). Steps 3-6 are independent and can happen in parallel.

### Terminal Strategy

- **iTerm2 + tmux**: Split-pane visual monitoring of all teammates
- **Ghostty + in-process**: Keyboard-based switching (Shift+Up/Down)
- Set `teammateMode` to `"auto"` (detects tmux) or `"in-process"`

---

## Operational Guardrails

### Reliability Criteria

If any of these become persistent problems, re-evaluate the Agent Teams integration:

- Teammates silently drop instructions (told to investigate X, wanders off to Y)
- Teammates hang or become unresponsive requiring manual intervention in >30% of sessions
- Lead loses track of teammate state — can't tell who's done what
- Inter-agent messages get lost or arrive out of order, causing duplicated or contradictory work
- Teammates fail to create worktrees or create them incorrectly despite explicit instructions
- Task completion signals are unreliable — lead thinks a task is done when it isn't, or vice versa
- Teammates can't reliably follow the `/start-task` → implement → `/finish-task` lifecycle without the lead babysitting each step
- A single teammate failure cascades (e.g., corrupts shared state, blocks other teammates)

---

## Verdict

Agent Teams gives us a better execution engine. BEADS gives us everything around it. The plumbing changes, the lifecycle stays: plan → track → execute → review → reconcile → compound.
