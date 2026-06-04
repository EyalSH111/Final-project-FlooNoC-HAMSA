#!/usr/bin/env bash
set -euo pipefail
REPO_NAME="ddp23_pnx_PoC"
OWNER="EyalSH111"
TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -z "$TOKEN" ]]; then
  echo "ERROR: Set GH_TOKEN or GITHUB_TOKEN"
  exit 1
fi
cd "$(dirname "$0")/.."
if [[ ! -d .git ]]; then
  echo "ERROR: run from repo with .git (use ~/ddp23_pnx_PoC after commit)"
  exit 1
fi
HTTP_CODE=$(curl -sS -o /tmp/gh_create.json -w "%{http_code}" -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/user/repos" \
  -d "{\"name\":\"${REPO_NAME}\",\"description\":\"HAMSA Stage-1 FlooNoC single-tile PoC\",\"private\":false}")
echo "create repo HTTP ${HTTP_CODE}"
head -c 300 /tmp/gh_create.json
echo ""
if [[ "$HTTP_CODE" != "201" && "$HTTP_CODE" != "422" ]]; then
  echo "ERROR: failed to create repo"
  exit 1
fi
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/${OWNER}/${REPO_NAME}.git"
git branch -M main
git push -u origin main
echo "OK: https://github.com/${OWNER}/${REPO_NAME}"
