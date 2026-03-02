#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_SOURCE="${ROOT_DIR}/zeabur.yaml"
TMP_TEMPLATE="$(mktemp -t zeabur-template.XXXXXX.yaml)"

cleanup() {
  rm -f "${TMP_TEMPLATE}"
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage:
  bash scripts/publish-template.sh [--repo owner/repo] [--branch branch] [--code TEMPLATE_CODE]

Examples:
  bash scripts/publish-template.sh --repo harrychuang/harryds-vibecoding-strapi
  bash scripts/publish-template.sh --repo harrychuang/harryds-vibecoding-strapi --code 7YJAKW

Options:
  --repo    GitHub repo in owner/repo format. If omitted, detect from git remote.
  --branch  Git branch for deployment (default: master).
  --code    Existing template code. When provided, run template update instead of create.
EOF
}

REPO=""
BRANCH="master"
TEMPLATE_CODE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --branch)
      BRANCH="${2:-}"
      shift 2
      ;;
    --code)
      TEMPLATE_CODE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "${TEMPLATE_SOURCE}" ]]; then
  echo "Missing template file: ${TEMPLATE_SOURCE}"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required. Install it first: brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Please login first: gh auth login"
  exit 1
fi

if [[ -z "${REPO}" ]]; then
  REMOTE_URL="$(git -C "${ROOT_DIR}" remote get-url origin 2>/dev/null || true)"
  if [[ "${REMOTE_URL}" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)?$ ]]; then
    REPO="${BASH_REMATCH[1]}"
  else
    echo "Cannot detect GitHub repo from origin. Please pass --repo owner/repo."
    exit 1
  fi
fi

echo "Using repository: ${REPO}"
REPO_ID="$(gh api "repos/${REPO}" --jq '.id')"
echo "Resolved repo ID: ${REPO_ID}"

cp "${TEMPLATE_SOURCE}" "${TMP_TEMPLATE}"
awk -v repo_id="${REPO_ID}" -v branch="${BRANCH}" '
  BEGIN {
    in_strapi = 0
    in_source = 0
    repo_done = 0
    branch_done = 0
  }
  {
    if ($0 ~ /^    - name: Strapi$/) {
      in_strapi = 1
    } else if ($0 ~ /^    - name: / && $0 !~ /^    - name: Strapi$/) {
      in_strapi = 0
      in_source = 0
    }

    if (in_strapi && $0 ~ /^        source:$/) {
      in_source = 1
    } else if (in_source && $0 ~ /^        [a-zA-Z]/ && $0 !~ /^          /) {
      in_source = 0
    }

    if (in_source && !repo_done && $0 ~ /^          repo:/) {
      print "          repo: " repo_id
      repo_done = 1
      next
    }

    if (in_source && !branch_done && $0 ~ /^          branch:/) {
      print "          branch: " branch
      branch_done = 1
      next
    }

    print $0
  }
' "${TMP_TEMPLATE}" > "${TMP_TEMPLATE}.next"
mv "${TMP_TEMPLATE}.next" "${TMP_TEMPLATE}"

if [[ -n "${TEMPLATE_CODE}" ]]; then
  echo "Updating template code: ${TEMPLATE_CODE}"
  npx zeabur@latest template update -c "${TEMPLATE_CODE}" -f "${TMP_TEMPLATE}"
else
  echo "Creating new template..."
  npx zeabur@latest template create -f "${TMP_TEMPLATE}"
fi
