#!/usr/bin/env bash
# Post-tool-use hook — run targeted tests + format checks after writes
# Triggered after Write(*.go), Write(*.proto), Write(policy.yaml)

set -u

FILE="${1:-}"
[ -z "$FILE" ] && exit 0

case "$FILE" in
  *.go)
    echo "→ gofmt + go vet on $FILE"
    gofmt -w "$FILE" || exit 1
    go vet "$(dirname "$FILE")/..." || {
      echo "❌ go vet failed in $(dirname "$FILE")" >&2
      exit 1
    }
    # Run tests in the package containing the changed file
    pkg=$(dirname "$FILE")
    if ls "$pkg"/*_test.go >/dev/null 2>&1; then
      go test "./$pkg/..." -count=1 -timeout 60s || {
        echo "❌ tests failed in $pkg" >&2
        exit 1
      }
    fi
    ;;

  *.proto)
    echo "→ regenerating protobuf bindings + running schema-compat tests"
    make proto || {
      echo "❌ protoc generation failed" >&2
      exit 1
    }
    make compat-test || {
      echo "❌ forward-compat against v6 schema failed" >&2
      echo "   MVP messages must parse with the v6 schema. Check field numbers." >&2
      exit 1
    }
    ;;

  *policy.yaml)
    echo "→ validating policy.yaml against MVP v1 schema"
    go run cmd/policy-validator/main.go --file "$FILE" --mvp || {
      echo "❌ policy validation failed" >&2
      exit 1
    }
    echo "→ running policy unit tests"
    go test ./internal/rules/... -count=1 -timeout 60s || {
      echo "❌ rule tests failed" >&2
      exit 1
    }
    echo "→ running HITL sanity check"
    go run cmd/check-hitl/main.go || {
      echo "❌ HITL-001 wiring check failed — release blocker" >&2
      exit 1
    }
    ;;

  *.ts)
    echo "→ eslint + prettier on $FILE"
    pkg_dir=$(dirname "$FILE" | sed 's|/src/.*||')
    if [ -f "$pkg_dir/package.json" ]; then
      (cd "$pkg_dir" && npx eslint "$FILE" --fix && npx prettier --write "$FILE") || exit 1
    fi
    ;;
esac

exit 0
