#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/release/sync_checksum_from_release.sh --tag vX.Y.Z [options]

Options:
  --tag <tag>           Git tag to sync checksum from (required), e.g. v0.1.0
  --repo <owner/repo>   GitHub repository (default: inferred from git remote)
  --workflow <name>     Workflow file/name to watch (default: precompiled_nifs.yml)
  --timeout <seconds>   Max wait for workflow completion (default: 1800)
  --no-commit           Download checksum but do not commit
  -h, --help            Show this help

Behavior:
  1) Wait for the precompiled NIF workflow run for the given tag.
  2) Watch it to completion and fail if it fails.
  3) Download checksum-Elixir.ExLanceDB.Nif.exs from the release.
  4) Commit checksum file unless --no-commit is set.
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

infer_repo() {
  local url
  url="$(git remote get-url origin)"

  case "$url" in
    git@github.com:*.git)
      echo "${url#git@github.com:}" | sed 's/\.git$//'
      ;;
    https://github.com/*)
      echo "${url#https://github.com/}" | sed 's/\.git$//'
      ;;
    *)
      echo "Could not infer GitHub repo from remote URL: $url" >&2
      exit 1
      ;;
  esac
}

TAG=""
REPO=""
WORKFLOW="precompiled_nifs.yml"
TIMEOUT="1800"
DO_COMMIT="1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      TAG="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --workflow)
      WORKFLOW="${2:-}"
      shift 2
      ;;
    --timeout)
      TIMEOUT="${2:-}"
      shift 2
      ;;
    --no-commit)
      DO_COMMIT="0"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$TAG" ]]; then
  echo "--tag is required" >&2
  usage
  exit 1
fi

require_cmd git
require_cmd gh

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

if [[ -z "$REPO" ]]; then
  REPO="$(infer_repo)"
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit/stash changes first." >&2
  exit 1
fi

echo "Repo:      $REPO"
echo "Tag:       $TAG"
echo "Workflow:  $WORKFLOW"
echo "Timeout:   ${TIMEOUT}s"

find_run_id() {
  gh run list \
    --repo "$REPO" \
    --workflow "$WORKFLOW" \
    --limit 100 \
    --json databaseId,event,headBranch,displayTitle,createdAt \
    --jq ".[] | select(.event == \"push\" and (.headBranch == \"$TAG\" or .displayTitle == \"$TAG\")) | .databaseId" \
    | head -n 1
}

start_epoch="$(date +%s)"
run_id=""

while [[ -z "$run_id" ]]; do
  now_epoch="$(date +%s)"
  elapsed="$((now_epoch - start_epoch))"

  if (( elapsed > TIMEOUT )); then
    echo "Timed out waiting for workflow run to appear for tag $TAG" >&2
    exit 1
  fi

  run_id="$(find_run_id || true)"
  if [[ -z "$run_id" ]]; then
    echo "Waiting for workflow run for tag $TAG ..."
    sleep 10
  fi
done

echo "Found workflow run id: $run_id"

gh run watch "$run_id" --repo "$REPO" --exit-status --interval 10

checksum_file="checksum-Elixir.ExLanceDB.Nif.exs"

echo "Downloading $checksum_file from release $TAG ..."

release_download_ok="0"
for attempt in {1..10}; do
  if gh release download "$TAG" --repo "$REPO" --pattern "$checksum_file" --clobber; then
    release_download_ok="1"
    break
  fi
  echo "Checksum download attempt $attempt failed; retrying in 10s..."
  sleep 10
done

if [[ "$release_download_ok" != "1" ]]; then
  echo "Failed to download $checksum_file from release $TAG" >&2
  exit 1
fi

if [[ ! -f "$checksum_file" ]]; then
  echo "Expected checksum file not found after download: $checksum_file" >&2
  exit 1
fi

if [[ "$DO_COMMIT" == "0" ]]; then
  echo "Checksum downloaded. --no-commit set, skipping commit."
  exit 0
fi

if git diff --quiet -- "$checksum_file"; then
  echo "Checksum file unchanged, nothing to commit."
  exit 0
fi

git add "$checksum_file"
git commit -m "chore(release): sync precompiled checksum for $TAG"

echo "Committed checksum update for $TAG"
