---
name: spec
description: "Use when you have an idea, goal, or feature description and need to turn it into an actionable plan with tasks"
allowed-tools: Read, Bash, Glob, Grep, Write, Edit, AskUserQuestion, Task, WebSearch, mcp__plugin_context7_context7__resolve-library-id, mcp__plugin_context7_context7__query-docs
---

# Spec: $ARGUMENTS

**Note: The current year is 2026.** Use this when dating plans and searching for documentation.

Transform ideas, feature descriptions, or improvement goals into well-structured plan documents with decomposed tasks. Use `--deepen` to enhance an existing plan with parallel research.

**NEVER CODE! Just research, plan, and decompose into tasks.**

## Argument Parsing

- `$ARGUMENTS` = feature description, plan reference, or `--deepen [plan-path]`
- If `--deepen` is present, jump to **Deepen Mode** below
- If no arguments, ask: "What would you like to plan? Describe the feature, problem, or improvement."

Do not proceed until you have a feature description.

---

## Normal Mode

### Phase 0: Assess & Refine

Evaluate whether the feature description needs refinement.

**Greenfield check**: If the feature is greenfield (new system, new major capability, or significant architectural change), suggest: "This looks like a greenfield feature. Consider running `/product-review` first to challenge scope and validate the approach before planning." If the feature is primarily UI/frontend, add: "This looks like a UI-heavy feature. Consider running `/product-review DESIGN` first to map user journeys and interaction patterns before planning." Proceed if user declines.

**If already detailed** (specific acceptance criteria, exact behavior, constrained scope):
Offer to skip: "Your requirements seem detailed enough. Should I proceed with research, or refine further?"

**Scope challenge** (run for all non-trivial features):
- What's the minimum set of changes that achieves the stated goal?
- **Complexity smell check**: If the plan will touch >8 files or introduce >2 new classes/services, challenge whether the same goal can be achieved with fewer moving parts
- **Existing code mandate**: Map every sub-problem to existing code/flows. Prefer reusing or extending over rebuilding.

**Otherwise, run interactive Q&A** using **AskUserQuestion** (one question at a time):

- **Problem space**: What problem? Who has it? What exists today?
- **Scope & constraints**: New project or existing? Timeline? Tech constraints? Non-negotiables?
- **Success criteria**: What does "done" look like?

Adapt questions based on answers. Exit when the idea is clear OR user says "proceed."

**Lightweight repo research** (parallel with dialogue):
- Task repo-research-analyst(feature_description) — existing patterns, CLAUDE.md guidance

**If 2-3 distinct approaches exist**, propose them with pros/cons and let user pick. Lead with your recommendation. Apply YAGNI.

**Gather signals** during refinement for research decision:
- User familiarity (pointing to examples = high)
- Topic risk (security, payments, external APIs = high)
- Uncertainty level (clear approach vs open-ended)

### Phase 1: Research

**Local research (always, parallel):**
- Task repo-research-analyst(feature_description)

**Research decision** based on signals from Phase 0:
- High-risk topics → always research externally
- Strong local context → skip external research
- Uncertainty or unfamiliar territory → research

Announce the decision briefly, then proceed.

**External research (conditional, parallel):**
- Task best-practices-researcher(feature_description)
- Task framework-docs-researcher(feature_description)

**Consolidate findings:** relevant file paths, external docs/URLs, CLAUDE.md conventions.

### Phase 2: Plan Structure

**Title & Categorization:**
- Draft clear title: `feat: Add User Authentication`, `fix: Cart Total Calculation`
- Determine type: enhancement, bug, refactor
- Filename: `YYYY-MM-DD-<type>-<descriptive-name>-plan.md` (3-5 words after prefix)

**SpecFlow Analysis:**
- Task spec-flow-analyzer(feature_description, research_findings)
- Incorporate gaps, edge cases, acceptance criteria updates

**Engineering lenses** (apply while writing Technical Considerations):
- Boring by default: are we using proven technology? Flag any novel choices as deliberate innovation-token spends.
- Reversibility: can this be rolled back without data loss? Feature flags needed?
- Systems over heroes: will this work when maintained by someone unfamiliar at 3am?
- Essential vs accidental complexity: is every new abstraction solving a real problem or one we created?

**Design lenses** (apply for plans with UI scope):
- Interaction states: specify loading/empty/error/success for every user-facing feature
- AI slop check: replace generic descriptions ("clean modern UI", "card grid") with specific design decisions
- Responsive: describe per-viewport behavior, not just "mobile-friendly"

**Choose detail level:**

#### MINIMAL — Simple bugs, small improvements, clear features
```markdown
---
title: [Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---
# [Title]
[Brief description]
## Acceptance Criteria
- [ ] Core requirement 1
## NOT in Scope
[Work considered and explicitly deferred, with one-line rationale each]
## Context
[Critical information]
## References
- [Links]
```

#### STANDARD — Most features, complex bugs, team collaboration
```markdown
---
title: [Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---
# [Title]
## Overview
[Comprehensive description]
## Problem Statement / Motivation
[Why this matters]
## Proposed Solution
[High-level approach]
## Technical Considerations
- Architecture impacts
- Performance implications
- Security considerations
## Acceptance Criteria
- [ ] Detailed requirement 1
- [ ] Testing requirements
## Success Metrics
[How we measure success]
## Dependencies & Risks
[What could block or complicate this]
## NOT in Scope
[Work considered and explicitly deferred, with one-line rationale each]
## What Already Exists
[Map each sub-problem to existing code/flows. Note whether plan reuses or rebuilds.]
## Architecture Diagram
[ASCII diagram: component boundaries, dependencies, data flow]
[Show happy path AND shadow paths (nil, empty, error)]
## Test Diagram
[Map every new codepath/flow to its required test]
| New Codepath/Flow | Test Type | Happy Path | Failure Path | Edge Case |
|-------------------|-----------|------------|--------------|-----------|
| ... | unit/integration/e2e | Y/N | Y/N | Y/N |
## Interaction States (include for plans with UI scope)
| Feature | Loading | Empty | Error | Success | Partial |
|---------|---------|-------|-------|---------|---------|
| ... | [what user sees] | ... | ... | ... | ... |
## Failure Modes
[For each new codepath: one realistic failure, whether a test covers it, whether error handling exists, whether user sees it or it's silent]
| Codepath | Failure Mode | Test? | Handled? | User Sees? |
|----------|-------------|-------|----------|------------|
| ... | ... | Y/N | Y/N | Error msg / Silent |

> Silent + no test + no handling = **CRITICAL GAP** — must be addressed before implementation.
## References & Research
- Similar implementations: [file_path:line_number]
- Best practices: [documentation_url]
- Related PRs: #[pr_number]
```

#### COMPREHENSIVE — Major features, architectural changes
```markdown
---
title: [Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---
# [Title]
## Overview
[Executive summary]
## Problem Statement
[Detailed problem analysis]
## Proposed Solution
[Comprehensive solution design]
## Technical Approach
### Architecture
[Detailed technical design]
### Implementation Phases
#### Phase 1: [Foundation]
- Tasks and deliverables
- Success criteria
- Estimated effort
#### Phase 2: [Core Implementation]
- Tasks and deliverables
- Success criteria
- Estimated effort
#### Phase 3: [Polish & Optimization]
- Tasks and deliverables
- Success criteria
- Estimated effort
## Alternative Approaches Considered
[Other solutions evaluated and why rejected]
## Acceptance Criteria
### Functional Requirements
- [ ] Detailed functional criteria
### Non-Functional Requirements
- [ ] Performance targets
- [ ] Security requirements
- [ ] Accessibility standards
### Quality Gates
- [ ] Test coverage requirements
- [ ] Documentation completeness
- [ ] Code review approval
## Success Metrics
[Detailed KPIs and measurement methods]
## Dependencies & Prerequisites
[Detailed dependency analysis]
## Risk Analysis & Mitigation
[Comprehensive risk assessment]
## Resource Requirements
[Team, time, infrastructure needs]
## Future Considerations
[Extensibility and long-term vision]
## Documentation Plan
[What docs need updating]
## NOT in Scope
[Work considered and explicitly deferred, with one-line rationale each]
## What Already Exists
[Map each sub-problem to existing code/flows. Note whether plan reuses or rebuilds.]
## Architecture Diagram
[ASCII diagram: component boundaries, dependencies, data flow]
[Show happy path AND shadow paths (nil, empty, error)]
## Test Diagram
[Map every new codepath/flow to its required test]
| New Codepath/Flow | Test Type | Happy Path | Failure Path | Edge Case |
|-------------------|-----------|------------|--------------|-----------|
| ... | unit/integration/e2e | Y/N | Y/N | Y/N |
## Interaction States (include for plans with UI scope)
| Feature | Loading | Empty | Error | Success | Partial |
|---------|---------|-------|-------|---------|---------|
| ... | [what user sees] | ... | ... | ... | ... |
## Reversibility Assessment
- Rollback procedure: [exact steps]
- Data migration reversibility: [Y/N, details]
- Feature flag strategy: [what to flag, kill switch]
- Deploy-time risk window: [what breaks between step 1 and step N]
## Failure Modes
[For each new codepath: one realistic failure, whether a test covers it, whether error handling exists, whether user sees it or it's silent]
| Codepath | Failure Mode | Test? | Handled? | User Sees? |
|----------|-------------|-------|----------|------------|
| ... | ... | Y/N | Y/N | Error msg / Silent |

> Silent + no test + no handling = **CRITICAL GAP** — must be addressed before implementation.
## References & Research
### Internal References
- Architecture decisions: [file_path:line_number]
- Similar features: [file_path:line_number]
### External References
- Framework documentation: [url]
- Best practices guide: [url]
### Related Work
- Previous PRs: #[pr_numbers]
- Related issues: #[issue_numbers]
```

**Write plan** to `docs/plans/`:
```bash
mkdir -p docs/plans
```

**Cross-reference:** Link related issues/PRs, reference specific file paths, add external resource links.

**Unresolved decisions:** If any question asked during Phase 0 goes unanswered or the user defers a decision, log it explicitly at the end of the plan as:

```markdown
## Unresolved Decisions
[Decisions deferred during planning that may affect implementation]
- [Question] — [Why it matters] — [Default assumption if not resolved]
```

Never silently default. Surface these so implementers know where ambiguity lives.

**Completion summary** — append to every STANDARD and COMPREHENSIVE plan:

```markdown
## Plan Review Summary
- Scope challenge: [passed / flagged N concerns]
- NOT in scope: [N items deferred]
- What already exists: [N items mapped]
- Architecture diagram: [included / N/A]
- Test diagram: [N codepaths mapped, N gaps]
- Interaction states: [included / N/A — no UI scope]
- Failure modes: [N mapped, N CRITICAL GAPS]
- Engineering review: [N issues found, N critical gaps]
- Design review: [scores per dimension / N/A — no UI scope]
- Unresolved decisions: [N open]
```

### Phase 2.5: Plan Review

Review the plan through engineering and design lenses before decomposition.
**Skip for MINIMAL plans.** For STANDARD and COMPREHENSIVE, this is mandatory.

**Depth scales with plan level:**

**STANDARD plans — Focused review:**
- Task general-purpose: "Read skills/plan-eng-review/SKILL.md for cognitive patterns and review methodology. Review the plan at [plan_path]. Return: top 5 engineering concerns ranked by severity, test coverage gaps, architecture diagram assessment, failure mode completeness, and any critical gaps (Silent + no test + no handling)."
- If plan has UI scope, also Task general-purpose: "Read skills/plan-design-review/SKILL.md for the design passes and cognitive patterns. Review the plan at [plan_path]. Return 0-10 score for: Interaction State Coverage, AI Slop Risk, Responsive & Accessibility. Flag specific gaps."
- Incorporate agent findings into the plan document.
- If any CRITICAL GAP found, surface via AskUserQuestion before proceeding.
- Amend Plan Review Summary with review results.

**COMPREHENSIVE plans — Full interactive review:**

Run the engineering review inline. Apply cognitive patterns from `skills/plan-eng-review/SKILL.md` throughout.

1. **Architecture review** — dependency graph, data flow, scaling, security. Production failure scenario per new codepath. ASCII diagram validation.
   STOP per issue. AskUserQuestion with options + recommendation + WHY.
2. **Code quality review** — organization, DRY, error handling gaps, edge cases.
   STOP per issue.
3. **Test review** — verify test diagram covers all new codepaths/flows.
   STOP per issue.
4. **Performance review** — N+1, memory, caching, slow paths.
   STOP per issue.

If plan has UI scope, also run design review passes (apply cognitive patterns from `skills/plan-design-review/SKILL.md`):

5. **Interaction State Coverage** — rate 0-10, fix gaps in the plan
6. **AI Slop Risk** — rate 0-10, rewrite vague descriptions with specific decisions
7. **Responsive & Accessibility** — rate 0-10, add per-viewport specs

Key cognitive patterns to apply throughout:
- **Boring by default** — flag novel technology. Is this spending an innovation token wisely?
- **Reversibility preference** — can every decision be undone?
- **Systems over heroes** — design for tired humans, not best engineer on best day
- **Two-week smell test** — can a competent engineer ship a feature in 2 weeks?
- **Subtraction default** — if a UI element doesn't earn its pixels, cut it

Amend plan with all findings. Update Plan Review Summary.

### Phase 3: Decompose into Beads

Check if beads is available:
```bash
bd list 2>/dev/null
```

**If `bd` is not available (command fails):**
Skip decomposition silently. Set `decomposed = false`. Proceed to Phase 4.

**If `bd` is available:**
Use **AskUserQuestion**:

**Question:** "Decompose this plan into beads tasks for tracking and dispatch?"
**Options:**
- "Yes, decompose into tasks"
- "No, plan only"

**If user selects "Yes":**
Set `decomposed = true`. Create tasks:

```bash
# Create epics (top-level containers)
bd create "<epic>" --type epic --priority <P1/P2/P3> --description "<description>"

# Create features and tasks WITH parent assignment (--parent = containment, not blocking)
bd create "<feature>" --type feature --priority <P1/P2/P3> --parent <epic-id> --description "<description>"
bd create "<task>" --type task --priority <P1/P2/P3> --parent <epic-id> --description "<description>"

# Wire execution-order dependencies BETWEEN SIBLING TASKS ONLY
# (task A must finish before task B can start — never use this for epic→task)
bd dep add <blocked-task> <blocking-task>

# Validate no circular dependencies
bd dep cycles 2>/dev/null

# Sync and display
bd sync
bd list
bd ready
```

#### Task Board Rules

> **`--parent`** = "this task belongs to this epic" (containment). Used at creation time.
> **`bd dep add`** = "this task cannot start until that task finishes" (execution ordering). Used between sibling tasks at the same level.
> **NEVER** use `bd dep add` to associate a task with its epic. That creates a deadlock.

> **`bd dep remove` trap:** Removes ALL relationship types between two IDs, including parent-child. If fixing a misplaced dependency, remove the dep FIRST, then set `--parent`. Never reverse this order.

> **Target files:** Include a `## Target Files` line in each task description listing the primary files the task will create or modify. This enables file-conflict detection during dispatch.

> **No transitive edges:** If A depends on B and B depends on C, do NOT also add A→C. Only direct edges.

> **No hardcoded migration/revision numbers:** Use "next available" in descriptions. Workers determine the actual number at implementation time after rebasing.

**If user selects "No":**
Set `decomposed = false`. Proceed to Phase 4.

### Phase 4: Post-Plan Menu

Use **AskUserQuestion** to present options:

**If `decomposed = true`:**

**Question:** "Plan created, reviewed, and decomposed into tasks. What next?"

**Options:**
1. **Deepen the plan** — Run `--deepen` mode for parallel research enhancement
2. **Full engineering review** — Run `/plan-eng-review` for interactive issue-by-issue walkthrough
3. **Full design review** — Run `/plan-design-review` for 7-pass scored review (only suggest if plan has UI scope)
4. **Review the plan** — Run `/multi-review` for specialized feedback
5. **Dispatch workers** — Run `/dispatch` to start parallel execution
6. **Work solo** — Pick a task with `/start-task`
7. **Create GitHub issue** — `gh issue create --title "<type>: <title>" --body-file <plan_path>`
8. **Simplify** — Reduce detail level

**If `decomposed = false`:**

**Question:** "Plan created and reviewed. What next?"

**Options:**
1. **Deepen the plan** — Run `--deepen` mode for parallel research enhancement
2. **Full engineering review** — Run `/plan-eng-review` for interactive issue-by-issue walkthrough
3. **Full design review** — Run `/plan-design-review` for 7-pass scored review (only suggest if plan has UI scope)
4. **Review the plan** — Run `/multi-review` for specialized feedback
5. **Create GitHub issue** — `gh issue create --title "<type>: <title>" --body-file <plan_path>`
6. **Simplify** — Reduce detail level
7. **Decompose now** — Create beads tasks from this plan

---

## Deepen Mode (`--deepen`)

Enhance an existing plan with parallel research agents, skill applications, and learnings.

### Step 1: Find Plan

If argument provided after `--deepen`, match it in `docs/plans/`. Otherwise find most recent:
```bash
ls -lt docs/plans/*.md 2>/dev/null | head -5
```
If no plans found: "No plans in `docs/plans/`. Run `/spec` first." Then STOP.

Read the plan file.

### Step 2: Parse and Analyze

Extract: sections, technologies/frameworks, domain areas, code examples, acceptance criteria.
Create a **section manifest** listing each section and what to research.

### Step 3: Discover and Apply Skills

```bash
ls .claude/skills/*/SKILL.md 2>/dev/null
ls ~/.claude/skills/*/SKILL.md 2>/dev/null
```

Read each skill's description. For every skill matching a plan section, spawn a parallel sub-agent:
- Task general-purpose: "Read [skill-path]/SKILL.md, apply the skill to [relevant plan section], return full output."

Spawn ALL matched skill sub-agents in PARALLEL.

### Step 4: Per-Section Research

For each major section:
- Task Explore agents for open-ended research
- Context7 MCP for framework documentation
- WebSearch for current (2024-2026) best practices

### Step 5: Run Review Agents

Discover ALL available agents:
```bash
find .claude/agents -name "*.md" 2>/dev/null
find ~/.claude/agents -name "*.md" 2>/dev/null
```

Launch ALL agents in parallel against the plan. Maximum coverage, not efficiency.

### Step 6: Synthesize

Collect outputs from all sources. Extract actionable recommendations, code patterns, anti-patterns, performance/security considerations, edge cases. Deduplicate, prioritize by impact, flag conflicts.

### Step 7: Enhance Plan Sections

Merge research back preserving original structure. Add **Research Insights** subsections with: Best Practices, Performance Considerations, Implementation Details (code examples), Edge Cases, References.

Add Enhancement Summary at top: date, sections enhanced, agents used, key improvements, new considerations.

### Step 8: Update Beads Tasks

```bash
bd update <id> --description "<enhanced description>"    # Refined tasks
bd create "<title>" --type task --parent <epic-id> --description "<desc>"  # New tasks (always assign parent)
bd close <id> --reason="Obsoleted during deepening"      # Obsolete tasks
bd sync
```

### Step 9: Post-Enhancement Menu

Check if beads tasks exist:
```bash
bd list 2>/dev/null
```

Use **AskUserQuestion**:

**If beads tasks exist:**

**Question:** "Plan deepened. What next?"

**Options:**
1. **View diff** — `git diff [plan_path]`
2. **Full engineering review** — Run `/plan-eng-review` for interactive walkthrough
3. **Full design review** — Run `/plan-design-review` for scored review (only suggest if UI scope)
4. **Run `/multi-review`** — Feedback from reviewers
5. **Run `/dispatch`** — Spawn parallel workers
6. **Run `/start-task <id>`** — Begin a specific task
7. **Deepen further** — Another round on specific sections

**If no beads tasks exist:**

**Question:** "Plan deepened. What next?"

**Options:**
1. **View diff** — `git diff [plan_path]`
2. **Full engineering review** — Run `/plan-eng-review` for interactive walkthrough
3. **Full design review** — Run `/plan-design-review` for scored review (only suggest if UI scope)
4. **Run `/multi-review`** — Feedback from reviewers
5. **Decompose into tasks** — Create beads tasks from this plan
6. **Deepen further** — Another round on specific sections
