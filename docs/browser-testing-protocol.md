# Browser Testing Protocol

Shared protocol for rigorous browser-based workflow testing. Referenced by `/finish-task`, `/multi-review`, and `/milestone-review`.

## Phase 1: Pre-Flight Checks

### 1a. Playwright MCP Availability

Check if Playwright MCP tools are available (e.g., `mcp__playwright__browser_navigate` exists as a callable tool). If not available:
- Log: "Playwright MCP not configured for this project. Skipping browser verification."
- Still produce the workflow analysis (Phase 2) as a **manual test checklist** — it has value without browser execution.
- STOP browser testing. Do not attempt to install or configure Playwright.

### 1b. Dev Server Detection

If the user hasn't provided a URL:
1. Scan common ports for a running server:
   ```bash
   for port in 3000 3001 5173 8080 8000 4200; do
     curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null && echo " → localhost:$port is up"
   done
   ```
2. If exactly one is found, confirm with user: "Found dev server at localhost:PORT. Use this?"
3. If multiple found or none found, ask user for the URL.
4. **Never auto-start a dev server.** Too many project-specific variables (env vars, databases, flags).

## Phase 2: Diff-to-Workflow Inference

Analyze the code diff to determine which user workflows were affected.

### 2a. File Classification

Classify each changed file by path/name patterns:

| File Pattern | Category | Workflow Type |
|---|---|---|
| `*Form*`, `*Input*`, `*Select*`, `*Checkbox*` | Form component | **Form** |
| `*Nav*`, `*Menu*`, `*Sidebar*`, `*Breadcrumb*` | Navigation | **Navigation** |
| `*Modal*`, `*Dialog*`, `*Drawer*`, `*Sheet*`, `*Popover*` | Overlay | **Modal/Dialog** |
| `*Table*`, `*List*`, `*Grid*`, `*DataGrid*` | Data display | **Data Display** |
| `*auth*`, `*login*`, `*signup*`, `*session*` | Auth | **Authentication** |
| `*cart*`, `*checkout*`, `*payment*`, `*order*` | Transaction | **CRUD/Transaction** |
| `pages/*`, `app/**/page.*`, `routes/*` | Route/page | Infer from page content |
| `api/*`, `services/*`, `hooks/use*` | Data layer | Trace consumers to find affected pages |
| `*.css`, `*.scss`, `tailwind.*` | Styling | Visual regression on affected components |
| `middleware.*`, `_app.*`, `layout.*`, `_layout.*` | Global wrapper | Test representative sample of all pages |
| `lib/*`, `utils/*`, `helpers/*` | Utility | Trace imports to find consuming components |

### 2b. Import-Chain Tracing

For shared components and utilities, trace the dependency chain:
```
changed file → which components import it → which pages/routes use those → affected routes
```

Use grep for import statements or read the project's route definitions.

### 2c. Workflow Proposal

Present inferred workflows to the user for confirmation. Be specific enough that wrong inferences are obvious:

```
Based on the diff, I identified these workflows to test:

1. **Form: User Settings** — /settings page
   Actions: Fill name/email fields, submit, verify persistence
   Trigger: UserSettingsForm.tsx changed

2. **Navigation: Sidebar** — all pages with sidebar
   Actions: Click each nav link, verify page loads, test active state
   Trigger: Sidebar.tsx changed

3. **Data Display: Users Table** — /admin/users
   Actions: Verify data renders, test sort/filter if present
   Trigger: UsersTable.tsx changed

Confirm, edit, or add workflows?
```

**If no workflows are inferrable** (changes to build config, types, dev tooling): exit cleanly with "No testable workflows detected. Skipping browser verification."

## Phase 3: Cache/Storage Clear

Clear ALL client-side state before testing. This ensures tests run against fresh code, not cached assets.

**Important:** `localStorage` and `sessionStorage` are per-origin — they require a page loaded at the target URL before they can be cleared. The correct sequence is: **navigate → clear → reload**.

**Step 1: Navigate to the first target URL** via `mcp__playwright__browser_navigate`.

**Step 2: Clear all state** (cookies are context-level, storage is per-origin on the loaded page):

```
mcp__playwright__browser_run_code:
  code: "async (page) => {
    await page.context().clearCookies();
    await page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
    });
    await page.evaluate(async () => {
      const keys = await caches.keys();
      await Promise.all(keys.map(k => caches.delete(k)));
      const regs = await navigator.serviceWorker.getRegistrations();
      await Promise.all(regs.map(r => r.unregister()));
    });
  }"
```

**Step 3: Reload the page** to render fresh without stale state. Navigate to the same URL again via `mcp__playwright__browser_navigate`.

**Do NOT re-clear between workflows** — this would destroy auth state. Clear once, authenticate once (if needed), then run all workflows.

**Note on HTTP cache:** There is no Playwright API for clearing HTTP cache ([playwright#30098](https://github.com/microsoft/playwright/issues/30098)). For HTTP cache isolation, configure Playwright MCP with the `--isolated` flag (see README). The `--isolated` flag starts each session with an ephemeral in-memory profile.

## Phase 4: Authentication Handling

After the cache clear and reload (Phase 3), check if the page shows a login form instead of the expected content.

**Detection:** Take a `browser_snapshot`. If the page contains a login form (inputs with type="password", labels containing "login"/"sign in"/"email"/"username"), the app requires auth.

**If auth is required, offer options via AskUserQuestion:**

```
This app requires authentication. How should I proceed?

1. **Provide test credentials** — I'll fill the login form (credentials stay in this conversation only)
2. **Log in manually** — I'll pause while you log in via the browser
3. **Test public pages only** — Skip workflows behind authentication
```

- Option 1: Fill login form with provided credentials, wait for redirect, proceed.
- Option 2: Pause, let user interact with browser directly, resume when they confirm.
- Option 3: Filter workflow list to public-only routes.
- **Never attempt OAuth flows** — third-party redirectors can't be reliably automated.

## Phase 5: Workflow Execution

Execute each confirmed workflow using the appropriate checklist below. For every workflow:

1. Navigate to the target URL
2. `browser_snapshot` — establish page structure (prefer snapshots over screenshots for interaction testing; snapshots are 2-5KB vs 100KB+ and expose semantic structure)
3. Execute the workflow-specific checklist
4. `browser_console_messages` — check for errors after each major interaction
5. Record observations

### Form Workflow

```
[ ] Identify all form fields from snapshot
[ ] Fill all fields with valid test data
[ ] Submit (click button AND try Enter key)
[ ] Verify success indicator (toast, redirect, confirmation message)
[ ] Verify submitted data appears in resulting page
[ ] Reload page — verify data persisted (catches optimistic-only updates)
[ ] Test with empty required fields — verify validation errors appear
[ ] Check console for errors during submission
```

### Navigation Workflow

```
[ ] Click each affected navigation element
[ ] Verify correct page loads (check heading/content via snapshot)
[ ] Verify URL updated correctly
[ ] Test browser back (browser_navigate_back) — verify previous page
[ ] Test deep link — navigate directly to URL, verify correct render
[ ] Verify active/selected state on navigation element
```

### CRUD Workflow

```
[ ] Create: fill form, submit, verify new item in list
[ ] Read: verify item displays with expected fields
[ ] Update: edit item, save, verify change
[ ] Delete: delete item, verify confirmation dialog, verify removal
[ ] Reload after each mutation — verify persistence
```

### Authentication Workflow

```
[ ] Login with valid credentials, verify redirect to authenticated page
[ ] Verify user identity displayed (username, avatar)
[ ] Refresh page — verify session persists
[ ] Navigate to protected route while logged out — verify redirect to login
[ ] Test logout — verify redirect, verify protected routes inaccessible
```

### Modal/Dialog Workflow

```
[ ] Trigger modal open
[ ] Verify modal appears (snapshot shows dialog role)
[ ] Interact with modal contents (fill forms, click buttons)
[ ] Close via close button
[ ] Close via Escape key (browser_press_key)
[ ] Verify underlying page unchanged after close
```

### Data Display Workflow

```
[ ] Verify data renders (not empty when data expected)
[ ] Verify column headers / field labels present
[ ] Test pagination if present (navigate to page 2)
[ ] Test sorting if present (click sort header)
[ ] Test filtering if present (apply filter, verify narrowed results)
[ ] Check empty state UI (if applicable)
```

### Responsive Check (always, after workflow tests)

```
[ ] browser_resize to desktop (1280x800) → browser_take_screenshot
[ ] browser_resize to mobile (375x812) → browser_take_screenshot
[ ] Verify no horizontal scrolling, no overlapping elements
```

## Phase 6: Reporting

### Severity Classification

| Severity | Criteria | Examples |
|----------|----------|---------|
| **Critical** | Workflow broken, data loss possible | Form submits but data not saved; page crashes; JS error prevents interaction |
| **Important** | Workflow works but with notable defects | Missing validation; broken mobile layout; missing loading state |
| **Minor** | Cosmetic or edge-case | Inconsistent spacing; missing empty state for rare condition |

### Report Format

```
## Browser Workflow Test Results

### Environment
- URL: <dev server URL>
- Cache cleared: Yes/No
- Authenticated: Yes/No/N/A

### Workflows Tested
1. **[Type]: [Name]** — [route]
   - Result: PASS / FAIL / PARTIAL
   - Observations: <what happened>
   - Issues: <if any, with severity>

### Console Errors
- <list any errors captured during testing>

### Screenshots
- Desktop (1280x800): [captured]
- Mobile (375x812): [captured]

### Issues Found
| Severity | Workflow | Issue | Details |
|----------|----------|-------|---------|
| Critical | Form: Settings | Data not persisted | Form submits successfully but reload shows old data |
| Important | Nav: Sidebar | Active state missing | Current page not highlighted in navigation |
```

## Edge Case Handling

- **Empty database**: If a data display or CRUD workflow shows empty state, report as observation, not failure: "Page rendered but displayed no data — may indicate empty database."
- **Flaky interactions**: If a click or form fill fails, retry once after 2 seconds. If still failing, report with timing context.
- **SPA vs SSR**: Don't try to detect. Use wait-for-content strategy for both: navigate, wait for expected elements, then interact.
- **No testable workflows**: Exit cleanly. Don't force testing when the diff doesn't affect user-visible behavior.
