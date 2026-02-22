#!/bin/bash
# Pre-commit secret scanner hook.
# Blocks git commit if staged files contain secrets or credentials.
#
# Uses gitleaks if available; falls back to regex pattern matching.
# Exit 0 = allow, Exit 2 = block with message on stderr

# Only inspect Bash tool calls
[ "$TOOL_NAME" = "Bash" ] || exit 0

# Extract the command from the tool input JSON
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null)
[ -n "$COMMAND" ] || exit 0

# Only care about git commit commands
echo "$COMMAND" | grep -qE '\bgit\s+commit\b' || exit 0

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
[ -n "$STAGED_FILES" ] || exit 0

# Filter out binary files and test fixtures
SCANNABLE_FILES=""
for f in $STAGED_FILES; do
  # Skip binary extensions
  case "$f" in
    *.png|*.jpg|*.jpeg|*.gif|*.ico|*.woff|*.woff2|*.ttf|*.eot|*.pdf|*.zip|*.tar|*.gz|*.bin|*.exe|*.so|*.dylib)
      continue ;;
  esac
  # Skip test fixtures
  case "$f" in
    *test/fixtures/*|*__fixtures__/*|*testdata/*)
      continue ;;
  esac
  SCANNABLE_FILES="$SCANNABLE_FILES $f"
done

[ -n "$SCANNABLE_FILES" ] || exit 0

# Try gitleaks first
if command -v gitleaks >/dev/null 2>&1; then
  GITLEAKS_OUTPUT=$(gitleaks protect --staged --no-banner 2>&1)
  GITLEAKS_EXIT=$?
  if [ $GITLEAKS_EXIT -ne 0 ]; then
    echo "SECRET SCAN BLOCKED: gitleaks found potential secrets in staged files." >&2
    echo "" >&2
    echo "$GITLEAKS_OUTPUT" >&2
    echo "" >&2
    echo "Remediation:" >&2
    echo "  - Remove the secret from the file" >&2
    echo "  - Use environment variables or a secrets manager instead" >&2
    echo "  - To allowlist a false positive, add it to .gitleaksignore" >&2
    exit 2
  fi
  exit 0
fi

# Fallback: regex pattern scanning (POSIX ERE — works on macOS and Linux)
PAT_AWS_KEY='AKIA[0-9A-Z]{16}'
PAT_AWS_SECRET='aws_secret_access_key[[:space:]]*[:=][[:space:]]*[A-Za-z0-9+/]{40}'
PAT_GH_TOKEN='gh[pousr]_[A-Za-z0-9_]{36,}'
PAT_API_KEY='(api[_-]?key|api[_-]?secret|access[_-]?token)[[:space:]]*[:=][[:space:]]*['"'"'"][A-Za-z0-9+/=]{20,}['"'"'"]'
PAT_PRIV_KEY='-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'
PAT_GENERIC='(password|passwd|secret)[[:space:]]*[:=][[:space:]]*['"'"'"][^'"'"'"]{8,}['"'"'"]'

FOUND_SECRETS=0
FINDINGS=""

scan_pattern() {
  local file="$1"
  local pattern="$2"
  local name="$3"
  local content="$4"
  local match
  match=$(echo "$content" | grep -oEi -e "$pattern" 2>/dev/null | head -1)
  if [ -n "$match" ]; then
    FINDINGS="${FINDINGS}  File: $file\n  Pattern: $name\n"
    FOUND_SECRETS=1
  fi
}

for f in $SCANNABLE_FILES; do
  [ -f "$f" ] || continue
  CONTENT=$(git show ":$f" 2>/dev/null) || continue

  scan_pattern "$f" "$PAT_AWS_KEY"     "AWS Access Key"              "$CONTENT"
  scan_pattern "$f" "$PAT_AWS_SECRET"  "AWS Secret Access Key"       "$CONTENT"
  scan_pattern "$f" "$PAT_GH_TOKEN"    "GitHub Token"                "$CONTENT"
  scan_pattern "$f" "$PAT_API_KEY"     "Generic API Key/Secret/Token" "$CONTENT"
  scan_pattern "$f" "$PAT_PRIV_KEY"    "Private Key"                 "$CONTENT"
  scan_pattern "$f" "$PAT_GENERIC"     "Generic Secret/Password"     "$CONTENT"
done

if [ $FOUND_SECRETS -ne 0 ]; then
  echo "SECRET SCAN BLOCKED: Potential secrets found in staged files." >&2
  echo "" >&2
  printf "%b" "$FINDINGS" >&2
  echo "" >&2
  echo "Remediation:" >&2
  echo "  - Remove the secret from the file" >&2
  echo "  - Use environment variables or a secrets manager instead" >&2
  echo "  - To skip this check for a false positive, add a comment: # noqa: secret-scan" >&2
  echo "    or install gitleaks and use .gitleaksignore for fine-grained allowlisting" >&2
  exit 2
fi

exit 0
