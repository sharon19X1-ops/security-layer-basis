#!/usr/bin/env bash
# Post-tool-use hook: format-check.sh
# Runs formatting and static analysis after a file is written.
# For Go: gofmt + go vet
# For TypeScript: eslint + prettier check
# Triggered on: Write(*.go) and Write(*.ts)

set -euo pipefail

FILE_PATH="${1:-}"

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"
PASS=true

case "$EXT" in
  go)
    echo "→ Post-write format check: Go ($FILE_PATH)"

    # gofmt — auto-fix in place
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH"
      echo "   ✅ gofmt applied"
    fi

    # go vet on the package
    PKG_DIR="$(dirname "$FILE_PATH")"
    if command -v go &>/dev/null; then
      if go vet "./$PKG_DIR/..." 2>&1; then
        echo "   ✅ go vet passed"
      else
        echo "   ❌ go vet found issues — fix before committing" >&2
        PASS=false
      fi
    fi

    # golangci-lint if available (non-blocking for single file edits)
    if command -v golangci-lint &>/dev/null; then
      golangci-lint run "$PKG_DIR/..." --out-format=line-number 2>&1 | head -30 || {
        echo "   ⚠️  golangci-lint found issues — run 'make lint' for full output"
      }
    fi
    ;;

  ts|tsx)
    echo "→ Post-write format check: TypeScript ($FILE_PATH)"

    # prettier — check and fix if available
    if command -v npx &>/dev/null; then
      npx --no prettier --write "$FILE_PATH" 2>/dev/null && echo "   ✅ prettier applied" || true

      # eslint
      npx --no eslint "$FILE_PATH" --fix 2>&1 | head -20 && echo "   ✅ eslint passed" || {
        echo "   ⚠️  eslint found issues" >&2
      }
    fi
    ;;

  *)
    exit 0
    ;;
esac

if [[ "$PASS" == "false" ]]; then
  echo ""
  echo "⚠️  Format check found issues. Fix them before committing." >&2
  echo "   Run 'make pre-commit' to run the full suite." >&2
  # Exit 0 — don't block the write, but warn clearly
fi

exit 0
