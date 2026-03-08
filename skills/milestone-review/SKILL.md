---
name: milestone-review
description: "Iterative review-fix loop for accumulated milestone/branch changes. Runs parallel reviewers, fixes findings autonomously, repeats until clean."
allowed-tools: Read, Bash, Glob, Grep, Edit, Write, Task, AskUserQuestion
---

# Milestone Review: Iterative Review-Fix Loop

You are running an autonomous review-fix loop on accumulated branch changes. Unlike `/multi-review` (which is interactive), you fix ALL verified findings yourself — iterating until the branch is clean.

## Section 1: Parse Arguments

Arguments: `$ARGUMENTS`

Parse the following flags:
- `--max-iterations N` — Maximum review-fix cycles (default: 5)
- `--base-branch <branch>` — Compare against this branch (default: main)
- `--severity <level>` — Minimum severity to fix: `critical`, `important`, `suggestions` (default: important — fixes Critical + Important)
- `--dry-run` — Report findings without fixing anything

## Section 2: Validate Environment

1. Confirm there are changes vs base:
   ```bash
   git diff <base-branch>...HEAD --stat
   ```
2. If no changes, exit early: "Nothing to review — branch is identical to `<base-branch>`."
3. Log scope:
   ```
   MILESTONE REVIEW STARTING
   Branch: <current branch>
   Base: <base-branch>
   Files changed: <count>
   Lines changed: +<added> -<removed>
   Max iterations: <N>
   Severity threshold: <level>
   ```

## Section 3: Review-Fix Loop

Iterate from 1 to `max_iterations`. Track findings across iterations to detect plateaus.

### Step 3.1: Compute Diff

```bash
git diff <base-branch>...HEAD --name-only
```

Read the full diff for reviewer context:
```bash
git diff <base-branch>...HEAD
```

### Step 3.2: Select Reviewers

Replicate multi-review's reviewer selection logic (Steps 1.5–3 of `/multi-review`):

1. Load `.claude/review.json` if present
2. Auto-detect frameworks from file patterns:
   | File Patterns | Agent |
   |--------------|-------|
   | `*.tsx`, `*.jsx`, `next.config.*`, `middleware.ts` | `nextjs-reviewer` |
   | `*.css`, `tailwind.*`, `components/ui/**` | `tailwind-reviewer` |
   | `*.py`, `alembic/**` | `python-backend-reviewer` |
   | `routes/**`, `api/**`, `endpoints/**`, `controllers/**` | `api-security-reviewer` |

3. **Always include** (milestone review is about cross-cutting concerns):
   - `code-simplicity-reviewer`
   - `pattern-recognition-specialist`
   - `architecture-strategist`

4. Conditionally include based on change types and risk tiers:
   - `security-sentinel` — auth, input handling, secrets, user data
   - `performance-oracle` — database queries, loops, caching
   - `agent-native-reviewer` — agent definitions, skill files, system prompts
   - `data-integrity-guardian` — database migrations, schema changes
   - `data-migration-expert` — data backfills, ID mappings

5. Apply `reviewers.exclude` / `reviewers.include` overrides from review config if present

Select 3–7 reviewers total.

### Step 3.3: Read Agent Definitions

For each selected reviewer:
```bash
cat ~/.claude/agents/review/<agent-name>.md
```

### Step 3.4: Launch Parallel Reviews

Use the Task tool to spawn parallel review agents. Each reviewer gets:
- The full diff context
- Contents of key changed files
- Instruction to return findings in standard format:

```markdown
## [Agent Name] Findings

### Critical Issues
- [file:line] Issue description - Confidence: X%

### Important Issues
- [file:line] Issue description - Confidence: X%

### Suggestions
- [file:line] Issue description - Confidence: X%
```

**Model selection:** Follow multi-review's tier-based logic. Default to Sonnet. Use Opus for `security-sentinel` and `architecture-strategist` when risk tier is critical.

### Step 3.5: Aggregate and Filter Findings

Process reviewer results:
- Include Critical and Important findings with confidence >= 80%
- Security findings (`security-sentinel`, `api-security-reviewer`) included regardless of confidence
- Include Suggestions only if `--severity suggestions` was passed
- Deduplicate findings that multiple reviewers flagged (keep the highest-confidence version)

### Step 3.6: Autonomous Fix Evaluation

**This is the key differentiator from `/multi-review`.** Multi-review splits findings into "auto-fixable" and "manual review recommended" and asks the user. Milestone-review rejects this distinction. You treat every verified finding as your responsibility to fix, regardless of complexity.

If `--dry-run`: report findings and exit. Do not fix anything.

For EACH Critical/Important finding:

1. **Verify**: Read actual code at file:line — confirm the finding is real. Reviewers hallucinate.
2. **Evaluate**: Is this a real issue? Drop ONLY if:
   - The finding is a false positive (code doesn't actually have the problem)
   - The finding is purely speculative/theoretical with no practical impact
   - Fixing it would require a human architectural decision (e.g., "should we use library X or Y?")
3. **Fix**: Implement the complete fix. Not a superficial patch — the real fix that fully resolves the issue. If the finding says "these 3 files have inconsistent error handling patterns," fix all 3 files.
4. **Track** each finding into one of:
   - `fixed[]` — issue was real, fix implemented
   - `dropped[]` — issue was false positive or speculative (log reason)
   - `deferred[]` — issue is real but requires human decision (log what decision is needed)

**Important**: The bar for deferring is HIGH. "This is complex" is NOT a valid reason to defer. "This requires choosing between two valid architectural approaches" IS.

### Step 3.7: Run Tests After Fixes

Auto-detect and run the project's test command:
- `pyproject.toml` → `uv run pytest`
- `package.json` → `pnpm test` (or `npm test` if no pnpm-lock)
- `Makefile` with `run-checks` → `make run-checks`
- `Makefile` with `test` → `make test`

If tests fail:
1. Diagnose the failure
2. If your fix caused it, adjust the fix (don't just revert and give up)
3. Only move to `deferred` if the fix genuinely can't be made to work without human guidance

Tests must pass before committing.

### Step 3.8: Commit Fixes

```bash
git add <specific files changed>
git commit -m "fix: address milestone review findings (iteration N)

- <list of issues fixed>

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 3.9: Check Exit Conditions

- **Clean**: Zero Critical/Important findings found this iteration → EXIT
- **Clean enough**: All findings were dropped as false positives → EXIT
- **Plateau**: No new findings compared to previous iteration (same issues re-flagged) → EXIT (likely false positives or unfixable without human input)
- **Limit**: Max iterations reached → EXIT (report deferred items)
- **Otherwise**: Next iteration (fixes may shift context; reviewers may flag different things)

### Step 3.10: Large Diff Handling

If the diff exceeds ~40 changed files, batch the review:
1. Group related files by directory or feature area
2. Run reviewers on each batch sequentially to stay within context limits
3. Fixes still accumulate into a single commit per iteration

## Section 4: Push and Report

```bash
git push
```

Generate the final report:

```
═══════════════════════════════════════════
MILESTONE REVIEW COMPLETE
═══════════════════════════════════════════
Branch: <branch>
Base: <base-branch>
Iterations: N
Findings evaluated: X
Fixed: Y
Dropped (false positive): Z
Deferred (needs human): W

FIXED:
- [file:line] issue (iteration N)
- ...

DEFERRED (if any):
- [file:line] issue — what human decision is needed
- ...

DROPPED:
- [file:line] issue — why it's a false positive
- ...
═══════════════════════════════════════════
```

## Section 5: Session Summary

Write a standard session summary to `docs/session_summaries/milestone-review_<timestamp>.txt` for orchestrator reconciliation. Include:
- Branch name and base branch
- Iteration count
- Full list of fixed, dropped, and deferred findings
- Test results
- Any deferred items that need human attention
