#!/usr/bin/env bash
# Pre-tool-use hook — scan for accidental secret exposure
# Runs before every Bash command and Write operation
# Exit 0 = allow; exit non-zero = block with reason
#
# Inherits from parent project. Same patterns + MVP-specific PSA credential patterns.

set -u

INPUT="${1:-}"
[ -z "$INPUT" ] && exit 0

# Patterns that indicate secret exposure
PATTERNS=(
  # Generic API keys / tokens / passwords
  '[A-Za-z0-9_-]*[Aa][Pp][Ii][_-]?[Kk][Ee][Yy][[:space:]]*=[[:space:]]*[A-Za-z0-9_-]{16,}'
  '[A-Za-z0-9_-]*[Ss][Ee][Cc][Rr][Ee][Tt][[:space:]]*=[[:space:]]*[A-Za-z0-9_-]{16,}'
  '[A-Za-z0-9_-]*[Tt][Oo][Kk][Ee][Nn][[:space:]]*=[[:space:]]*[A-Za-z0-9_-]{20,}'
  '[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd][[:space:]]*=[[:space:]]*[^[:space:]]{8,}'
  # AWS
  'AKIA[0-9A-Z]{16}'
  'aws_secret_access_key[[:space:]]*=[[:space:]]*[A-Za-z0-9/+=]{40}'
  # Private keys
  '-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----'
  # GitHub
  'ghp_[A-Za-z0-9]{36}'
  'gho_[A-Za-z0-9]{36}'
  'ghs_[A-Za-z0-9]{36}'
  # Slack
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  # ConnectWise PSA (MVP-specific)
  'CW_PRIVATE_KEY[[:space:]]*=[[:space:]]*[A-Za-z0-9]{16,}'
  'CW_PUBLIC_KEY[[:space:]]*=[[:space:]]*[A-Za-z0-9]{16,}'
  # Vault / generic high-entropy
  'hvs\.[A-Za-z0-9_-]{24,}'
  'hvb\.[A-Za-z0-9_-]{24,}'
)

# Dangerous file reads
DANGEROUS_READS=(
  'cat[[:space:]]+.*\.env([[:space:]]|$)'
  'cat[[:space:]]+.*\.env\.[a-z]+'
  'cat[[:space:]]+.*id_rsa([[:space:]]|$)'
  'cat[[:space:]]+.*id_ed25519'
  'cat[[:space:]]+.*\.pem'
  'cat[[:space:]]+.*\.key([[:space:]]|$)'
  'cat[[:space:]]+.*credentials'
  'cat[[:space:]]+.*\.aws/credentials'
  'cat[[:space:]]+.*\.ssh/id_'
  'printenv[[:space:]]+.*([Kk][Ee][Yy]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Tt][Oo][Kk][Ee][Nn]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd])'
  'env[[:space:]]*\|[[:space:]]*grep[[:space:]]+.*([Kk][Ee][Yy]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Tt][Oo][Kk][Ee][Nn])'
)

for pat in "${PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qE "$pat"; then
    echo "❌ secrets-scan: blocked — pattern looks like a secret literal" >&2
    echo "   Hint: use \${VAR_NAME} reference, never inline secrets" >&2
    exit 1
  fi
done

for pat in "${DANGEROUS_READS[@]}"; do
  if echo "$INPUT" | grep -qE "$pat"; then
    echo "❌ secrets-scan: blocked — command attempts to read credential file" >&2
    echo "   This is exactly what FS-002 detects in production. Don't do it in dev either." >&2
    exit 1
  fi
done

exit 0
