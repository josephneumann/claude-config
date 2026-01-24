---
name: compound
description: "This skill should be used when the user has solved a non-trivial problem and wants to document the solution for future reference. Triggers on phrases like 'that worked', 'fixed it', 'problem solved', 'figured it out', or when explicitly invoked with /compound."
---

# Compound: Capture Learnings

You are capturing a solution to a problem that was just solved. This creates institutional knowledge for future sessions.

## Workflow

### Step 1: Detect Trigger

This skill activates when:
- User explicitly runs `/compound`
- User indicates a problem was solved ("that worked", "fixed it", "figured it out")
- A debugging session concludes successfully

### Step 2: Determine Scope (BLOCKING - Ask User)

Use `AskUserQuestion` to determine where this learning belongs:

```
I'd like to document this solution. First, is this learning:

1. **Project-specific** — Applies only to this codebase (e.g., "CruxMD's FHIR loader expects X format")
2. **Global/reusable** — Applies across projects (e.g., "pgvector requires specific index settings for cosine similarity")
```

**Routing:**
- **Project-specific** → `./docs/solutions/` (current project)
- **Global** → `~/.claude/docs/solutions/` (claude-config, shared across all projects)

### Step 3: Gather Context (BLOCKING - Ask User)

Use `AskUserQuestion` to gather the following. Do NOT proceed until you have clear answers:

```
Can you help me capture the key details?
```

**Questions to ask:**
1. **Module/Area**: Which part of the codebase was affected?
2. **Symptom**: What was the observable problem? (error message, unexpected behavior)
3. **Root Cause**: What was actually wrong?
4. **Solution**: What fixed it?
5. **Prevention**: How can this be avoided in the future?

### Step 4: Search Existing Solutions

Check if a similar solution already exists in BOTH locations:

```bash
# Search project-specific solutions
grep -ri "<module>" docs/solutions/ --include="*.md" -l 2>/dev/null | head -5

# Search global solutions
grep -ri "<module>" ~/.claude/docs/solutions/ --include="*.md" -l 2>/dev/null | head -5

# Search for similar symptoms (both locations)
grep -ri "<symptom-keyword>" docs/solutions/ ~/.claude/docs/solutions/ --include="*.md" -l 2>/dev/null | head -5
```

If a similar solution exists, ask the user if they want to:
- Update the existing document
- Create a new document (different enough to warrant separation)
- Skip documentation (already covered)

### Step 5: Generate Filename

Format: `[symptom-slug]-[module]-YYYYMMDD.md`

Example: `import-error-authentication-20260124.md`

Rules:
- Lowercase with hyphens
- Symptom first (what you'd search for)
- Module second (where it happened)
- Date last (for versioning)

### Step 6: Validate YAML Frontmatter

Use this schema for the frontmatter:

```yaml
---
scope: <project|global>
module: <affected-module>
date: <YYYY-MM-DD>
problem_type: <one of: build-error, test-failure, runtime-error, performance, database, security, integration, logic-error, workflow>
symptoms:
  - <observable symptom 1>
  - <observable symptom 2>
root_cause: <one of: missing-dependency, config-error, race-condition, incorrect-assumption, api-change, missing-validation, resource-exhaustion, logic-flaw, documentation-gap, other>
severity: <one of: critical, high, medium, low>
tags:
  - <relevant-tag-1>
  - <relevant-tag-2>
---
```

### Step 7: Create Document

**For project-specific learnings:**
Create in `./docs/solutions/[category]/`

**For global learnings:**
Create in `~/.claude/docs/solutions/[category]/`

| problem_type | Directory |
|--------------|-----------|
| build-error | `docs/solutions/build-errors/` |
| test-failure | `docs/solutions/test-failures/` |
| runtime-error | `docs/solutions/runtime-errors/` |
| performance | `docs/solutions/performance/` |
| database | `docs/solutions/database/` |
| security | `docs/solutions/security/` |
| integration | `docs/solutions/integration/` |
| logic-error | `docs/solutions/logic-errors/` |
| workflow | `docs/solutions/workflow/` |

**Document Template:**

```markdown
---
[frontmatter from Step 6]
---

# [Descriptive Title]

## Symptom

[What the user observed - error messages, unexpected behavior]

## Investigation

[Brief summary of how the problem was diagnosed]

## Root Cause

[What was actually wrong]

## Solution

[What fixed it - be specific with code/config changes]

## Prevention

[How to avoid this in the future]

## Related

- [Links to related docs, issues, or solutions]
```

### Step 8: Decision Menu

After creating the document, present options:

```
Solution documented at: [path]/[category]/[filename].md

What would you like to do next?
1. Continue working (done documenting)
2. Add a reminder to CLAUDE.md (if this is a project-wide gotcha)
3. Create a follow-up task (if there's related work to do)
```

## Example Flow

**User**: "Finally figured out why pgvector wasn't returning results - needed to set the index to use cosine distance"

**Assistant**:
```
I'd like to document this solution. Is this learning:
1. Project-specific (only applies to this codebase)
2. Global/reusable (applies across projects)
```

**User**: "Global - this applies to any project using pgvector"

**Assistant**:
```
Got it, I'll save this to the global solutions. A few quick questions:
1. Module: pgvector/embeddings
2. Symptom: Vector search returning no results despite valid embeddings?
3. Root Cause: Index using wrong distance metric?

Is that accurate? And what was the specific fix?
```

**User**: "Yes, had to use `vector_cosine_ops` instead of the default"

**Assistant creates**: `~/.claude/docs/solutions/database/pgvector-no-results-embeddings-20260124.md`

## Directory Setup

If directories don't exist, create them:

```bash
# Project-specific
mkdir -p docs/solutions/{build-errors,test-failures,runtime-errors,performance,database,security,integration,logic-errors,workflow}

# Global (should already exist via claude-config)
mkdir -p ~/.claude/docs/solutions/{build-errors,test-failures,runtime-errors,performance,database,security,integration,logic-errors,workflow}
```

## Important Notes

- **Always ask about scope first** — Route to the right location before gathering details
- Always ask before creating documents — the user confirms the details
- Keep solutions focused — one problem per document
- Use searchable terms in symptoms and tags
- Link to related solutions when patterns repeat
- Global learnings compound across ALL projects — high value for reusable knowledge
- Project-specific learnings stay with the project — don't pollute global with project details
