#!/usr/bin/env bash
# Pre-tool-use hook: lint-check.sh
# Runs lint on Go or TypeScript files before a Write operation completes.
# Provides early feedback before the file is saved, catching errors immediately.
# Triggered on: Write operations targeting *.go or *.ts files.

set -euo pipefail

FILE_PATH="${1:-}"

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"
PROJECT_DIR="$(git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null || echo "")"

case "$EXT" in
  go)
    echo "→ Pre-write lint: Go ($FILE_PATH)"
    if command -v gofmt &>/dev/null; then
      # Check if content (passed via stdin) would pass gofmt
      CONTENT=$(cat)
      FORMATTED=$(echo "$CONTENT" | gofmt 2>&1)
      DIFF=$(diff <(echo "$CONTENT") <(echo "$FORMATTED") || true)
      if [[ -n "$DIFF" ]]; then
        echo "⚠️  gofmt would reformat this file. Run 'gofmt -w $FILE_PATH' after saving." >&2
        # Non-blocking — warn only, don't block the write
      fi
    fi

    if command -v go &>/dev/null && [[ -n "$PROJECT_DIR" ]]; then
      # Vet the package (quick, catches common errors)
      PKG_DIR="$(dirname "$FILE_PATH")"
      go vet "$PKG_DIR/..." 2>&1 || {
        echo "⚠️  go vet found issues in $PKG_DIR — review before committing" >&2
        # Non-blocking for pre-write (file not saved yet)
      }
    fi
    ;;

  ts|tsx)
    echo "→ Pre-write lint: TypeScript ($FILE_PATH)"
    if command -v npx &>/dev/null && [[ -n "$PROJECT_DIR" ]]; then
      # TypeScript type check (quick, non-blocking)
      npx --no tsc --noEmit --strict 2>&1 | head -20 || {
        echo "⚠️  TypeScript type errors found — review output above" >&2
      }
    fi
    ;;

  yaml|yml)
    echo "→ Pre-write lint: YAML ($FILE_PATH)"
    if command -v python3 &>/dev/null; then
      CONTENT=$(cat)
      echo "$CONTENT" | python3 -c "
import sys, yaml
try:
    yaml.safe_load(sys.stdin)
    print('✅ YAML syntax valid')
except yaml.YAMLError as e:
    print(f'❌ YAML syntax error: {e}', file=sys.stderr)
    sys.exit(1)
" || exit 1
    fi
    ;;

  *)
    # No lint check for other file types
    exit 0
    ;;
esac

exit 0
