#!/usr/bin/env bash
# Detect the project's language and package manager from its manifest files, and whether it has a Dockerfile.
# Writes language, package_manager and has_dockerfile to $GITHUB_OUTPUT. Run from the project directory.
set -euo pipefail

language="${1:-}"
if [ -z "$language" ]; then
  if [ -f package.json ]; then language=node
  elif [ -f pom.xml ] || [ -f build.gradle ] || [ -f build.gradle.kts ]; then language=java
  elif [ -f go.mod ]; then language=go
  elif [ -f pyproject.toml ] || [ -f requirements.txt ] || [ -f setup.py ]; then language=python
  elif [ -f composer.json ]; then language=php
  elif [ -f Cargo.toml ]; then language=rust
  else
    echo "::error::No package.json, pom.xml, build.gradle, go.mod, pyproject.toml, requirements.txt, composer.json or Cargo.toml here. Set the language input."
    exit 1
  fi
fi

case "$language" in
  node)
    if [ -f pnpm-lock.yaml ]; then pm=pnpm
    elif [ -f yarn.lock ]; then pm=yarn
    else pm=npm; fi ;;
  java)
    if [ -f pom.xml ]; then pm=maven; else pm=gradle; fi ;;
  go|python|php|rust) pm="" ;;
  *) echo "::error::Unsupported language '$language'"; exit 1 ;;
esac

has_dockerfile=false
[ -f Dockerfile ] && has_dockerfile=true

echo "Detected: language=$language package_manager=${pm:-none} dockerfile=$has_dockerfile"
{
  echo "language=$language"
  echo "package_manager=$pm"
  echo "has_dockerfile=$has_dockerfile"
} >> "$GITHUB_OUTPUT"
