#!/usr/bin/env bash
# Run the project's tests. Usage: test.sh <language> [package_manager]. Run after build.sh.
# A failing test fails the step. A project with no tests passes with a warning, so the gap stays visible.
set -euo pipefail
language="$1"; pm="${2:-}"

PYTEST_VERSION=9.1.1

has_script() { node -e "process.exit(require('./package.json').scripts?.[process.argv[1]] ? 0 : 1)" "$1"; }
no_tests() { echo "::warning::No tests found for this $language project"; }

case "$language" in
  node)
    if has_script test; then "$pm" test; else no_tests; fi ;;
  python)
    python -c "import pytest" 2>/dev/null || python -m pip install "pytest==$PYTEST_VERSION"
    # pytest exits 5 when it collects no tests; treat that as "no tests", every other non-zero as a failure.
    rc=0; python -m pytest || rc=$?
    if [ "$rc" -eq 5 ]; then no_tests; elif [ "$rc" -ne 0 ]; then exit "$rc"; fi ;;
  go)
    go test -race ./... ;;
  java)
    if [ "$pm" = maven ]; then
      mvn_cmd=mvn; [ -x ./mvnw ] && mvn_cmd=./mvnw
      "$mvn_cmd" -B -ntp verify
    else
      gradle_cmd=gradle; [ -x ./gradlew ] && gradle_cmd=./gradlew
      "$gradle_cmd" test
    fi ;;
  php)
    if [ -x vendor/bin/phpunit ]; then vendor/bin/phpunit; else no_tests; fi ;;
  rust)
    if [ -f Cargo.lock ]; then cargo test --locked; else cargo test; fi ;;
  *) echo "::error::Unsupported language '$language'"; exit 1 ;;
esac
