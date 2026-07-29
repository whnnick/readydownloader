#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
EXPECTED_TAG="${1:-}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION is not semantic: $VERSION" >&2
  exit 1
fi

grep -Fq "## [$VERSION] - " "$ROOT_DIR/CHANGELOG.md"
grep -Fq "## [$VERSION] - " "$ROOT_DIR/CHANGELOG.zh-CN.md"

if [[ -n "$EXPECTED_TAG" ]]; then
  [[ "$EXPECTED_TAG" == "v$VERSION" ]] || {
    echo "Tag $EXPECTED_TAG does not match VERSION $VERSION." >&2
    exit 1
  }
  if grep -Fq "## [$VERSION] - Unreleased" "$ROOT_DIR/CHANGELOG.md" ||
     grep -Fq "## [$VERSION] - 未发布" "$ROOT_DIR/CHANGELOG.zh-CN.md"; then
    echo "The $VERSION changelog entry must have a release date before tagging." >&2
    exit 1
  fi
fi

echo "Release version consistency verified: $VERSION"
