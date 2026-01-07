---
description: Generate handoff context for passing a task to a separate agent session
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

# Handoff Task: $ARGUMENTS

Generate context to hand off task `$ARGUMENTS` to another agent session.

## 1. Validate Task

```bash
bd show $ARGUMENTS
```

If the task doesn't exist or is ambiguous, use AskUserQuestion to get clarification from the user.

## 2. Understand Task Scope

From the task details, note:
- Title and description
- Dependencies (blocked-by, blocks)
- Priority and type
- Parent epic context (if any)

## 3. Gather Session Context

Think about what you know from THIS session that would help another agent. Consider:

- **Decisions made**: What approaches were chosen and why?
- **Gotchas discovered**: What pitfalls or edge cases should they watch for?
- **Related context**: What patterns, files, or code did you discover that's relevant?
- **Recommended approach**: What strategy would you suggest?
- **Key files**: Which files should they read first?

If you don't have enough context from the current session, use AskUserQuestion to ask the user what guidance they'd like to include.

## 4. Generate Handoff

Output a complete, copy-pasteable command. The handoff context should be:
- **Single line**: NO line breaks in the handoff text (must be one continuous line for easy terminal copy-paste)
- **Actionable**: Specific guidance, not vague suggestions
- **Supplementary**: Don't repeat what's in the task description

Format:

```
==============================================
HANDOFF: $ARGUMENTS
==============================================

Task: <title>
Priority: <priority>
Type: <type>

To start this task in a new session, run:

/start-task $ARGUMENTS --handoff "<your-context-here>"

Suggested handoff context:
---
<Summarize decisions, gotchas, approach, and relevant notes from this session.
Keep it concise but actionable. Think: what would YOU want to know if starting fresh?>
---

==============================================
```

## Important Notes

- The handoff should NOT include task details (the new agent reads those from beads)
- The handoff should NOT include project docs (start-task gathers CLAUDE.md, README, etc.)
- Focus on session-specific insights that would otherwise be lost
- Keep the handoff text short enough to copy/paste easily
