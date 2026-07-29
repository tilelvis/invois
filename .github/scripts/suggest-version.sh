#!/usr/bin/env bash
# Suggests the next semantic version bump based on Conventional Commits
# since the last release tag. Never writes anywhere — read-only.
#
# Recognized commit prefixes:
#   feat:              -> minor
#   fix:, perf:         -> patch
#   any type + "!"      -> major   (e.g. "feat!: ..." or "fix!: ...")
#   "BREAKING CHANGE"   -> major   (anywhere in the commit body)
#   docs:, chore:, refactor:, test:, style:, ci:, build: -> no bump on their own
#
# Output: writes a Markdown summary to $GITHUB_STEP_SUMMARY (if set) and
# also prints it to stdout. Exits 0 always — this is advisory, never fails CI.

set -euo pipefail

CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//' | cut -d'+' -f1)

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$LAST_TAG" ]; then
  COMMIT_RANGE="HEAD"
  RANGE_LABEL="all commits (no previous tag found)"
else
  COMMIT_RANGE="${LAST_TAG}..HEAD"
  RANGE_LABEL="commits since ${LAST_TAG}"
fi

# %s = subject, %b = body (so multi-line "BREAKING CHANGE:" footers are caught)
COMMITS=$(git log ${COMMIT_RANGE} --pretty=format:'%s%n%b%n---COMMIT-END---' 2>/dev/null || echo "")

if [ -z "$COMMITS" ]; then
  echo "No commits found in range (${RANGE_LABEL}); nothing to suggest."
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
      echo "## 📦 Version suggestion"
      echo ""
      echo "No commits found since \`${LAST_TAG:-the beginning of history}\` — nothing to suggest."
    } >> "$GITHUB_STEP_SUMMARY"
  fi
  exit 0
fi

BUMP="none"
declare -a FEAT_LINES=()
declare -a FIX_LINES=()
declare -a BREAKING_LINES=()
declare -a OTHER_LINES=()

while IFS= read -r line; do
  [ "$line" = "---COMMIT-END---" ] && continue
  [ -z "$line" ] && continue

  if echo "$line" | grep -qiE '^BREAKING CHANGE:'; then
    BREAKING_LINES+=("$line")
    BUMP="major"
    continue
  fi

  if echo "$line" | grep -qE '^[a-zA-Z]+(\([^)]*\))?!:'; then
    BREAKING_LINES+=("$line")
    BUMP="major"
    continue
  fi

  if echo "$line" | grep -qE '^feat(\([^)]*\))?:'; then
    FEAT_LINES+=("$line")
    [ "$BUMP" != "major" ] && BUMP="minor"
    continue
  fi

  if echo "$line" | grep -qE '^(fix|perf)(\([^)]*\))?:'; then
    FIX_LINES+=("$line")
    [ "$BUMP" = "none" ] && BUMP="patch"
    continue
  fi

  if echo "$line" | grep -qE '^(docs|chore|refactor|test|style|ci|build)(\([^)]*\))?:'; then
    OTHER_LINES+=("$line")
    continue
  fi
done <<< "$COMMITS"

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

case "$BUMP" in
  major)
    SUGGESTED="$((MAJOR + 1)).0.0"
    ;;
  minor)
    SUGGESTED="${MAJOR}.$((MINOR + 1)).0"
    ;;
  patch)
    SUGGESTED="${MAJOR}.${MINOR}.$((PATCH + 1))"
    ;;
  *)
    SUGGESTED="$CURRENT_VERSION"
    ;;
esac

{
  echo "## 📦 Version suggestion"
  echo ""
  echo "Current version: \`${CURRENT_VERSION}\`"
  echo "Based on ${RANGE_LABEL}."
  echo ""
  if [ "$BUMP" = "none" ]; then
    echo "No \`feat:\`, \`fix:\`, \`perf:\`, or breaking-change commits found — **no version bump suggested**."
  else
    echo "Suggested next version: **\`${SUGGESTED}\`** (${BUMP} bump)"
  fi
  echo ""

  if [ "${#BREAKING_LINES[@]}" -gt 0 ]; then
    echo "### 💥 Breaking changes"
    for l in "${BREAKING_LINES[@]}"; do echo "- ${l}"; done
    echo ""
  fi
  if [ "${#FEAT_LINES[@]}" -gt 0 ]; then
    echo "### ✨ Features"
    for l in "${FEAT_LINES[@]}"; do echo "- ${l}"; done
    echo ""
  fi
  if [ "${#FIX_LINES[@]}" -gt 0 ]; then
    echo "### 🐛 Fixes / perf"
    for l in "${FIX_LINES[@]}"; do echo "- ${l}"; done
    echo ""
  fi
  if [ "${#OTHER_LINES[@]}" -gt 0 ]; then
    echo "<details><summary>Other commits (no version impact)</summary>"
    echo ""
    for l in "${OTHER_LINES[@]}"; do echo "- ${l}"; done
    echo ""
    echo "</details>"
    echo ""
  fi

  echo "---"
  echo "_This is advisory only — nothing was changed. To release, update \`pubspec.yaml\` to \`${SUGGESTED}+1\`, commit, and push a \`v${SUGGESTED}\` tag._"
} | tee -a "${GITHUB_STEP_SUMMARY:-/dev/stdout}"
