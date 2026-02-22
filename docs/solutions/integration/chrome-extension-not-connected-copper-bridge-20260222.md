---
scope: global
module: claude-code-chrome
date: 2026-02-22
problem_type: integration
symptoms:
  - "Browser extension is not connected"
  - "Invalid token or user mismatch"
  - claude-in-chrome MCP tools return connection error
root_cause: config-error
severity: medium
tags: [claude-code, chrome-extension, mcp, copper-bridge, websocket, unix-socket, growthbook]
is_bug_fix: false
has_regression_test: false
test_files_modified: []
regression_test_status: skipped
---

# Chrome Extension "Not Connected" — copper_bridge Flag Fix

## Symptom

All `mcp__claude-in-chrome__*` tools fail with:

> Browser extension is not connected. Please ensure the Claude browser extension is installed and running...

The extension IS installed and running. Restarting Chrome, re-logging into claude.ai, and killing processes don't help. The underlying error is "Invalid token or user mismatch" in the WebSocket bridge authentication.

The issue may appear intermittently — working one day and broken the next.

## Investigation

- Verified Chrome extension installed and enabled
- Verified logged into claude.ai with the same account as Claude Code
- Restarted Chrome — no effect
- Killed all related processes — no effect
- All standard troubleshooting steps from the error message failed

The key insight: the issue is intermittent because a feature flag is periodically re-cached from Anthropic's GrowthBook servers.

## Root Cause

The `tengu_copper_bridge` feature flag in `~/.claude.json` controls how the MCP server communicates with the Chrome extension:

- **`true`** (default when rolled out): Uses a **cloud WebSocket bridge** that requires OAuth token validation. This bridge can fail with "Invalid token or user mismatch" when the token state is inconsistent.
- **`false`**: Uses a **local Unix socket** that connects directly to the native host process. No cloud authentication needed.

The flag lives at `cachedGrowthBookFeatures.tengu_copper_bridge` in `~/.claude.json` and is periodically refreshed from Anthropic's GrowthBook feature flag service. This means:
- It can change from `false` to `true` without user action
- The issue appears/disappears based on server-side feature rollout
- All the standard workarounds (re-login, kill processes, restart Chrome) address symptoms of the cloud bridge auth, not the root cause

## Solution

Edit `~/.claude.json` and set the flag to `false`:

```json
{
  "cachedGrowthBookFeatures": {
    "tengu_copper_bridge": false
  }
}
```

If `cachedGrowthBookFeatures` already exists with other keys, just change `tengu_copper_bridge` to `false`.

Then restart the session:

```bash
claude --chrome
```

### Important Caveat

The flag is periodically re-cached from Anthropic's GrowthBook servers, so it **may revert to `true`**. If the error returns, just set it back to `false`. This is a workaround until the cloud bridge authentication is fixed upstream.

## Prevention

- If Chrome extension stops connecting, check `tengu_copper_bridge` first before any other troubleshooting
- Consider adding a check to session startup hooks that verifies this flag
- Monitor for upstream fixes in Claude Code release notes that may resolve the cloud bridge auth permanently

## Related

- No existing documentation found on this issue
- Affects all projects using `claude --chrome` or `mcp__claude-in-chrome__*` tools
