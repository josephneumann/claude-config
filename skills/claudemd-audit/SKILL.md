---
name: claudemd-audit
description: "Use when the user wants to audit CLAUDE.md files for bloat, staleness, misplacement, or information architecture issues. Invoked with /claudemd-audit."
allowed-tools: Read, Bash, Glob, Grep, Edit, Write, AskUserQuestion, Agent
---

# CLAUDE.md Audit

Every line in always-loaded context must pass: "Would removing this cause Claude to make mistakes?"

## Arguments

- No args / `--project`: Project CLAUDE.md + architecture
- `--global`: `~/.claude/CLAUDE.md` + global skills/hooks
- `--all`: Global + project + child dirs
- `--fix`: Apply fixes interactively after report

## Phase 1: Discovery

Map the architecture before auditing files. Use Glob/Read to find:

- **Always-loaded**: `./CLAUDE.md` + `@imports`, `~/.claude/CLAUDE.md` + `@imports`, `AGENTS.md`
- **On-demand**: `.claude/skills/*/SKILL.md`, child `CLAUDE.md` files
- **Enforcement**: `.claude/settings.json` hooks, `.pre-commit-config.yaml`, `.githooks/`
- **Reference**: `docs/*.md`, `Makefile`
- **Tooling**: Linter configs, build systems (`package.json`, `Cargo.toml`, `pyproject.toml`)

## Phase 2: Per-File Audit (28 checks)

Use Grep/Read for evidence. Do not guess.

**A. Bloat** — 1. Line count (flag >200, warn >150, target <100/<50 global) 2. Linter-territory rules (cross-ref linter configs) 3. Self-evident instructions ("write clean code") 4. Conventions Claude already knows 5. AI verbosity (reuse `/humanizer` patterns; 3+ triggers = flag) 6. Tutorials (>3 sentences, no actionable rule) 7. File-by-file descriptions (>10 lines)

**B. Staleness** — 8. Dead file refs (verify with `ls`) 9. Dead commands (check `which`/`command -v`) 10. Dead `@import` refs 11. Stale branch/PR refs (check `git branch -a`)

**C. Misplacement** — 12. Should be a hook (deterministic rules; redundant if enforced, suggest hook if not) 13. Should be a skill (domain knowledge >20 lines) 14. Should be in docs/ (>30 lines; use `@import`)

**D. Duplication** — 15. Global↔project overlap 16. CLAUDE.md↔skill overlap 17. CLAUDE.md↔hook overlap

**E. Missing Essentials** — 18. No build/test commands (Makefile/package.json exists but undocumented) 19. No branch conventions 20. Missing `@imports` for docs/ markdown

**F. Structure** — 21. Mixed concerns (commands + style + architecture blended) 22. Missing project CLAUDE.md (`--all`) 23. Unnecessary child CLAUDE.md

**G. Architecture** — 24. Always-loaded budget (CLAUDE.md + @imports + AGENTS.md total; flag >500 lines) 25. Tier separation (operational essentials only in CLAUDE.md; domain → skills; reference → docs) 26. Cross-ref hygiene (pointers not inlined content; no circular refs) 27. Makefile `help` target (reference `make help` instead of listing targets) 28. Hook coverage gap (advisory text vs deterministic enforcement)

## Scoring (0-100)

Line count (15): 15/10/5/0 at <100/<150/<200/>200. Bloat (15): -3/finding. Staleness (10): -5/dead ref. Misplacement (15): -3/block. Duplication (10): -3/dup. Essentials (10): +5 build/test, +5 branch conventions. Structure (10): -3/issue. Architecture (15): +5 tiers, +5 budget, +5 cross-refs.

90+ Lean & well-architected / 70-89 Good / 50-69 Needs attention / <50 Overhaul

## Output

Architecture table → per-file results table → category findings with line numbers → suggested improvements.

## Fix Mode (`--fix`)

Report → ask which fixes to apply → Edit → re-audit for new score.

## Gold Standard

Intactus (75 lines): three-tier progressive discovery. CLAUDE.md has branch workflow + Makefile commands + env vars + architecture pointers. Domain knowledge in `.claude/skills/shadcn/` (hub-and-spoke). Deep reference in `docs/`. Every line passes the litmus test.
