#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FILES="$(git ls-files --cached --others --exclude-standard)"
DENIED_FILE_CANDIDATES="$(grep -Ev '(^|/)\.env\.example$' <<< "$FILES" || true)"

if grep -Ei '(^|/)(\.codex|\.agents|\.vs|tools|dist|x64|Downloads)(/|$)|(^|/)\.env($|\.)|yt_cookies\.txt$|\.(pdb|obj|ipch|tlog|part)$' <<< "$DENIED_FILE_CANDIDATES"; then
  echo "Repository contains a denied tracked or unignored file." >&2
  exit 1
fi

secret_pattern='-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|sk-[A-Za-z0-9_-]{20,}'
private_path_pattern='/Users/[A-Za-z0-9._-]+/|[A-Za-z]:\\Users\\[^\\]+\\'

while IFS= read -r file; do
  [[ -n "$file" && "$file" != "script/scan_repository.sh" ]] || continue
  scan_status=0
  grep -I -n -E -e "$secret_pattern|$private_path_pattern" -- "$file" || scan_status=$?
  if [[ "$scan_status" == "0" ]]; then
    echo "Repository contains a credential-like value or private developer path." >&2
    exit 1
  elif [[ "$scan_status" != "1" ]]; then
    echo "Repository scan failed while reading: $file" >&2
    exit "$scan_status"
  fi
done <<< "$FILES"

echo "Repository sensitive-information scan passed."
