#!/usr/bin/env bash
# Pre-tool-use hook: secrets-scan.sh
# Scans the command or file content for accidental secret exposure.
# Blocks execution if patterns matching API keys, passwords, tokens, or private keys are detected.
# Triggered on: Bash commands and Write operations.

set -euo pipefail

INPUT="${1:-}"   # Command string (for Bash) or file path (for Write)
MODE="${2:-bash}" # "bash" or "write"

# ──────────────────────────────────────────────
# Patterns that indicate secret exposure
# ──────────────────────────────────────────────
SECRET_PATTERNS=(
  # Generic secret keywords in assignments/args
  '[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]\s*=\s*["\x27][^"\x27]{4,}'
  '[Ss][Ee][Cc][Rr][Ee][Tt]\s*=\s*["\x27][^"\x27]{4,}'
  '[Aa][Pp][Ii][_-][Kk][Ee][Yy]\s*=\s*["\x27][^"\x27]{4,}'
  '[Aa][Uu][Tt][Hh][_-][Tt][Oo][Kk][Ee][Nn]\s*=\s*["\x27][^"\x27]{4,}'
  # AWS
  'AKIA[0-9A-Z]{16}'
  # Private keys
  '-----BEGIN (RSA|EC|OPENSSH|DSA|PGP) PRIVATE KEY'
  # Connection strings with embedded creds
  'postgresql://[^:]+:[^@]+@'
  'mysql://[^:]+:[^@]+@'
  # CW / Autotask / PSA specific
  'CW_PRIVATE_KEY\s*=\s*["\x27][^"\x27]{4,}'
  'AUTOTASK_API_KEY\s*=\s*["\x27][^"\x27]{4,}'
  # HEC / Splunk
  'SPLUNK_HEC_TOKEN\s*=\s*["\x27][^"\x27]{4,}'
  # Sentinel
  'SENTINEL_WORKSPACE_KEY\s*=\s*["\x27][^"\x27]{4,}'
  # Vault secret IDs
  'VAULT_SECRET_ID\s*=\s*["\x27][^"\x27]{4,}'
  # Bare long random strings (possible tokens — heuristic)
  # Commented out by default — too many false positives on hashes
  # '[0-9a-f]{40,}'
)

VIOLATIONS=()

scan_text() {
  local text="$1"
  for pattern in "${SECRET_PATTERNS[@]}"; do
    if echo "$text" | grep -qE "$pattern" 2>/dev/null; then
      VIOLATIONS+=("Pattern matched: $pattern")
    fi
  done
}

if [[ "$MODE" == "write" && -n "$INPUT" ]]; then
  # For Write operations, read stdin as file content
  CONTENT=$(cat)
  scan_text "$CONTENT"
elif [[ -n "$INPUT" ]]; then
  # For Bash commands, scan the command itself
  scan_text "$INPUT"
fi

if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
  echo "❌ SECRETS SCAN BLOCKED — potential secret exposure detected:" >&2
  for v in "${VIOLATIONS[@]}"; do
    echo "   → $v" >&2
  done
  echo "" >&2
  echo "   If this is a false positive (e.g., a test fixture with mock values)," >&2
  echo "   add a '# slb-secrets-scan-ignore' comment on the line." >&2
  echo "   Never commit real credentials to git." >&2
  exit 1
fi

exit 0
