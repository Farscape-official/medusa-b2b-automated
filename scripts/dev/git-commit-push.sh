#!/bin/bash

# ==============================================================================
# Farscape Enterprise Sync Script (Non-Interactive / CI-Ready)
# Function: Automated, Secure, Token-Based Git Sync
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# 0. Resolve Project Root
# ------------------------------------------------------------------------------

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# ------------------------------------------------------------------------------
# 1. Load Environment Variables
# ------------------------------------------------------------------------------

ENV_FILE="env/.env.dev"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# ------------------------------------------------------------------------------
# 2. Input Handling (Args > Env > Defaults)
# ------------------------------------------------------------------------------

TARGET_BRANCH="${1:-${TARGET_BRANCH:-main}}"
COMMIT_MSG="${2:-${COMMIT_MSG:-"auto: sync $(date +'%Y-%m-%d %H:%M')"}}"

LOG_DIR="/var/log/farscape"
LOG_FILE="$LOG_DIR/sync_$(date +'%Y%m').log"

# ------------------------------------------------------------------------------
# 3. Pre-flight Checks
# ------------------------------------------------------------------------------

# Git repo check
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "❌ Not inside a Git repository"
    exit 1
}

# Token check (for HTTPS) — skip if token already embedded in remote URL
REMOTE_CHECK=$(git remote get-url origin)
if ! echo "$REMOTE_CHECK" | grep -q "^git@"; then
    if ! echo "$REMOTE_CHECK" | grep -qE "https://[^@]+@"; then
        [[ -z "${GITHUB_TOKEN:-}" ]] && {
            echo "❌ GITHUB_TOKEN not found and no token in remote URL (required for HTTPS)"
            exit 1
        }
    fi
fi

# Logging setup
mkdir -p "$LOG_DIR"
chmod 750 "$LOG_DIR"

# ------------------------------------------------------------------------------
# 4. Remote & Branch Setup
# ------------------------------------------------------------------------------

REMOTE_URL=$(git remote get-url origin)

# Configure token auth if HTTPS and not already embedded
if [[ "$REMOTE_URL" =~ ^https://github.com/ ]] && [[ -n "${GITHUB_TOKEN:-}" ]]; then
    AUTH_URL=$(echo "$REMOTE_URL" | sed "s#https://#https://${GITHUB_TOKEN}@#")
    git remote set-url origin "$AUTH_URL"
fi

# Fetch latest state
git fetch origin --quiet

# Prevent detached HEAD
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

if [[ "$CURRENT_BRANCH" == "detached" ]]; then
    echo "❌ Detached HEAD detected. Aborting."
    exit 1
fi

# Checkout / Create branch
if [[ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]]; then
    git checkout -B "$TARGET_BRANCH" "origin/$TARGET_BRANCH" 2>/dev/null \
        || git checkout -B "$TARGET_BRANCH"
fi

# ------------------------------------------------------------------------------
# 5. Main Sync Execution
# ------------------------------------------------------------------------------

{
    echo "================================================"
    echo "Sync Started: $(date)"
    echo "Branch      : $TARGET_BRANCH"
    echo "Repository  : $REMOTE_URL"
    echo "================================================"

    echo "📦 Staging files (tracked + untracked)..."
    git add -A

    echo "🔍 Checking for changes..."

    if git diff-index --quiet HEAD --; then
        echo "ℹ️ No changes to commit."
    else
        echo "💾 Committing..."
        git commit -m "$COMMIT_MSG"
    fi

    echo "🚀 Pushing to origin/$TARGET_BRANCH..."

    git push -u origin "$TARGET_BRANCH"

    echo "✅ Sync completed successfully."
    echo "Finished: $(date)"
    echo "================================================"

} 2>&1 | tee -a "$LOG_FILE"
