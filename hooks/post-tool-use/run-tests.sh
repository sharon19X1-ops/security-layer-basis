#!/usr/bin/env bash
# Post-tool-use hook: run-tests.sh
# Runs the relevant test suite after a file is written.
# For policy.yaml: runs policy validation + policy unit tests.
# For Go files: runs tests for the affected package.
# Triggered on: Write(policy.yaml), Write(*.go)

set -euo pipefail

FILE_PATH="${1:-}"
PROJECT_DIR="$(git -C "$(dirname "${FILE_PATH:-$(pwd)}")" rev-parse --show-toplevel 2>/dev/null || echo ".")"

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

FILENAME="$(basename "$FILE_PATH")"
EXT="${FILE_PATH##*.}"

# ──────────────────────────────────────────────
# policy.yaml — validate schema + run policy tests
# ──────────────────────────────────────────────
if [[ "$FILENAME" == "policy.yaml" ]]; then
  echo "→ Policy changed — running validation"
  cd "$PROJECT_DIR"

  if command -v go &>/dev/null && [[ -f "cmd/policy-validator/main.go" ]]; then
    go run cmd/policy-validator/main.go --file "$FILE_PATH" && \
      echo "   ✅ Policy validation passed" || {
      echo "   ❌ Policy validation FAILED — see errors above" >&2
      exit 1
    }
  else
    echo "   ⚠️  Policy validator not built yet — skipping (run 'make build' first)"
  fi

  # Run policy unit tests
  if command -v go &>/dev/null && [[ -d "internal/policy" ]]; then
    go test ./internal/policy/... -v 2>&1 | tail -20 && \
      echo "   ✅ Policy unit tests passed" || {
      echo "   ❌ Policy unit tests FAILED" >&2
      exit 1
    }
  fi

  exit 0
fi

# ──────────────────────────────────────────────
# Go files — run tests for the affected package
# ──────────────────────────────────────────────
if [[ "$EXT" == "go" ]]; then
  PKG_DIR="$(dirname "$FILE_PATH")"
  echo "→ Go file changed — running tests for $PKG_DIR"
  cd "$PROJECT_DIR"

  go test "./$PKG_DIR/..." -count=1 -timeout=60s 2>&1 && \
    echo "   ✅ Package tests passed" || {
    echo "   ❌ Package tests FAILED — fix before committing" >&2
    echo "   Run 'make test' for full test suite output" >&2
    # Non-blocking — tests run but don't block the write
    # The pre-commit hook will enforce hard blocking
  }

  exit 0
fi

exit 0
