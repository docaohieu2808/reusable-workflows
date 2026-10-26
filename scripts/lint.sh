#!/usr/bin/env bash
# Run the language's standard linter. Usage: lint.sh <language> [package_manager]. Run after build.sh.
set -euo pipefail
language="$1"; pm="${2:-}"

# Linter versions are pinned so a new linter release cannot turn a green pipeline red on its own.
RUFF_VERSION=0.17.2
STATICCHECK_VERSION=2026.2.2

has_script() { node -e "process.exit(require('./package.json').scripts?.[process.argv[1]] ? 0 : 1)" "$1"; }

case "$language" in
  node)
    if has_script lint; then "$pm" run lint; else echo "::notice::No lint script in package.json"; fi ;;
  python)
    python -m pip install "ruff==$RUFF_VERSION"
    ruff check . ;;
  go)
    go vet ./...
    go run "honnef.co/go/tools/cmd/staticcheck@$STATICCHECK_VERSION" ./... ;;
  java)
    echo "::notice::No Java linter is run; add Checkstyle or SpotBugs to the build and it runs in the build step" ;;
  php)
    find . -name '*.php' -not -path './vendor/*' -print0 | xargs -0 -r -n1 php -l ;;
  rust)
    cargo fmt --all -- --check
    cargo clippy --all-targets -- -D warnings ;;
  *) echo "::error::Unsupported language '$language'"; exit 1 ;;
esac
