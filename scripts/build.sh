#!/usr/bin/env bash
# Install dependencies and build. Usage: build.sh <language> [package_manager]. Run from the project directory.
# Any failing command fails the step: nothing here is allowed to swallow an error.
set -euo pipefail
language="$1"; pm="${2:-}"

has_script() { node -e "process.exit(require('./package.json').scripts?.[process.argv[1]] ? 0 : 1)" "$1"; }

case "$language" in
  node)
    case "$pm" in
      pnpm) pnpm install --frozen-lockfile ;;
      yarn) yarn install --immutable ;;
      *) if [ -f package-lock.json ]; then npm ci; else npm install; fi ;;
    esac
    if has_script build; then "$pm" run build; else echo "No build script in package.json, skipping build"; fi ;;
  python)
    python -m pip install --upgrade pip
    [ -f requirements.txt ] && python -m pip install -r requirements.txt
    [ -f requirements-dev.txt ] && python -m pip install -r requirements-dev.txt
    # An unknown extra is only a warning in pip, so asking for [test] is safe when the project has none.
    if [ -f pyproject.toml ] || [ -f setup.py ]; then python -m pip install -e ".[test]"; fi
    python -m compileall -q -x '(^|/)(\.venv|venv|node_modules)/' . ;;
  go)
    go mod download
    go build ./... ;;
  java)
    if [ "$pm" = maven ]; then
      mvn_cmd=mvn; [ -x ./mvnw ] && mvn_cmd=./mvnw
      "$mvn_cmd" -B -ntp -DskipTests package
    else
      gradle_cmd=gradle; [ -x ./gradlew ] && gradle_cmd=./gradlew
      "$gradle_cmd" build -x test
    fi ;;
  php)
    composer validate --no-check-publish
    composer install --no-interaction --prefer-dist --no-progress ;;
  rust)
    if [ -f Cargo.lock ]; then cargo build --locked; else cargo build; fi ;;
  *) echo "::error::Unsupported language '$language'"; exit 1 ;;
esac
