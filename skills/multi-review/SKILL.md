---
name: multi-review
description: "This skill should be used when the user wants a comprehensive code review using multiple specialized reviewers in parallel. Invoked with /multi-review or when user asks for 'thorough review', 'full code review', or 'review from multiple perspectives'."
---

# Multi-Review: Parallel Specialized Code Review

You are orchestrating a comprehensive code review using multiple specialized review agents in parallel.

## Workflow

### Step 1: Identify Changes

Determine what code to review:

```bash
# If in a PR/branch context
git diff main...HEAD --name-only

# Or for staged changes
git diff --cached --name-only

# Or recent changes
git diff HEAD~5 --name-only
```

List the changed files and their types (e.g., `.py`, `.ts`, `.go`).

### Step 2: Analyze Change Types

Categorize the changes to select appropriate reviewers:

| Change Type | Indicators | Relevant Reviewers |
|------------|------------|-------------------|
| Auth/Security | login, auth, password, token, jwt, permission | security-sentinel |
| Performance | query, cache, loop, batch, async, database | performance-oracle |
| Architecture | new files, interface, refactor, module | architecture-strategist |
| Patterns | any code change | pattern-recognition-specialist |
| Complexity | any code change | code-simplicity-reviewer |

### Step 3: Select Reviewers

Always include:
- `code-simplicity-reviewer` (YAGNI, complexity)
- `pattern-recognition-specialist` (anti-patterns, conventions)

Conditionally include:
- `security-sentinel` - if auth, input handling, secrets, or user data
- `performance-oracle` - if database queries, loops, caching, or data operations
- `architecture-strategist` - if structural changes, new modules, or interface changes

**Select 3-5 reviewers** based on the change types identified.

### Step 4: Read Agent Definitions

For each selected reviewer, read the agent definition:

```bash
cat ~/.claude/agents/review/<agent-name>.md
```

Or if symlinked:
```bash
cat ~/Code/claude-config/agents/review/<agent-name>.md
```

### Step 5: Launch Parallel Reviews

Use the Task tool to spawn parallel review agents (use Sonnet model for efficiency):

```
Launch these agents in parallel:

1. Task: code-simplicity-reviewer
   - Subagent type: general-purpose
   - Model: sonnet
   - Prompt: [agent definition] + [files to review]

2. Task: pattern-recognition-specialist
   - Subagent type: general-purpose
   - Model: sonnet
   - Prompt: [agent definition] + [files to review]

3. Task: [additional selected reviewer]
   ...
```

Each agent should return findings in this format:
```markdown
## [Agent Name] Findings

### Critical Issues
- [Issue with file:line] - Confidence: X%

### Important Issues
- [Issue with file:line] - Confidence: X%

### Suggestions
- [Issue with file:line] - Confidence: X%
```

### Step 6: Aggregate Findings

Combine results from all reviewers, sorted by severity:

```markdown
## Multi-Review Summary

### Reviewers
- [x] code-simplicity-reviewer
- [x] pattern-recognition-specialist
- [x] security-sentinel
- [ ] performance-oracle (not applicable)
- [ ] architecture-strategist (not applicable)

### Critical Issues (Confidence >= 80%)
| File:Line | Issue | Reviewer | Confidence |
|-----------|-------|----------|------------|
| ... | ... | ... | ...% |

### Important Issues (Confidence >= 80%)
| File:Line | Issue | Reviewer | Confidence |
|-----------|-------|----------|------------|
| ... | ... | ... | ...% |

### Suggestions (Confidence >= 80%)
| File:Line | Issue | Reviewer | Confidence |
|-----------|-------|----------|------------|
| ... | ... | ... | ...% |

### Low-Confidence Findings (< 80%)
[Collapsed/summarized - these may be false positives]
```

### Step 7: Filter Results

Only surface findings with **confidence >= 80%**. Lower confidence findings should be mentioned but not emphasized - they may be false positives.

### Step 8: Offer Auto-Fix

For Critical and Important issues with clear fixes:

```
Would you like me to auto-fix the high-confidence issues?

Auto-fixable:
1. [file:line] - [issue] - [proposed fix summary]
2. [file:line] - [issue] - [proposed fix summary]

Manual review recommended:
3. [file:line] - [issue] - [reason it needs human judgment]

Options:
1. Fix all auto-fixable issues
2. Fix specific issues (provide numbers)
3. Skip auto-fix, I'll handle manually
```

## Agent Reference

### code-simplicity-reviewer
**Focus**: YAGNI, complexity reduction, unnecessary code
**Always include**: Yes
**Path**: `agents/review/code-simplicity-reviewer.md`

### security-sentinel
**Focus**: OWASP Top 10, input validation, auth, secrets
**Include when**: Auth code, user input, API endpoints, secrets handling
**Path**: `agents/review/security-sentinel.md`

### performance-oracle
**Focus**: N+1 queries, memory leaks, caching, async patterns
**Include when**: Database operations, loops over data, caching changes
**Path**: `agents/review/performance-oracle.md`

### pattern-recognition-specialist
**Focus**: Anti-patterns, code conventions, consistency
**Always include**: Yes
**Path**: `agents/review/pattern-recognition-specialist.md`

### architecture-strategist
**Focus**: SOLID principles, design patterns, module structure
**Include when**: New files, interface changes, structural refactoring
**Path**: `agents/review/architecture-strategist.md`

## Example Invocation

**User**: `/multi-review`

**Assistant**:
1. Identifies changed files from git
2. Categorizes changes (e.g., "auth module changes, new API endpoint")
3. Selects reviewers (simplicity, patterns, security, architecture)
4. Launches 4 parallel Task agents
5. Aggregates results
6. Presents findings sorted by severity
7. Offers to auto-fix high-confidence issues

## Important Notes

- Parallel execution is key - don't run reviewers sequentially
- Filter to >= 80% confidence to reduce noise
- Security findings should always be surfaced even at lower confidence
- Maximum 5 reviewers to keep reviews focused
