# Global Solutions

This directory contains **global learnings** — solutions and patterns that apply across all projects.

## Structure

```
docs/solutions/
├── build-errors/      # Compilation, bundling, dependency issues
├── test-failures/     # Test suite failures
├── runtime-errors/    # Exceptions, crashes at runtime
├── performance/       # Slow operations, memory issues
├── database/          # Query issues, migrations, data integrity
├── security/          # Vulnerabilities, auth issues
├── integration/       # Third-party API, service communication
├── logic-errors/      # Incorrect business logic
└── workflow/          # Development process, tooling issues
```

## Usage

### Adding learnings

Run `/compound` and select "Global/reusable" when asked about scope.

### Searching learnings

The `learnings-researcher` agent automatically searches both this global location and project-specific `docs/solutions/` directories.

```bash
# Manual search
grep -ri "<keyword>" ~/.claude/docs/solutions/ --include="*.md"
```

## What belongs here?

**Good candidates for global learnings:**
- Framework/library gotchas (e.g., "pgvector requires specific index settings")
- General development patterns (e.g., "async context managers need explicit cleanup")
- Tool configuration (e.g., "pytest-asyncio requires mode=auto for fixtures")
- Common error resolutions that apply to any project using that technology

**Keep project-specific:**
- Business logic specific to one codebase
- Project-specific configuration
- Domain-specific patterns (e.g., "CruxMD's FHIR loader expects X format")
