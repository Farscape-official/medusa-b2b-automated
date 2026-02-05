#!/bin/bash

# ==============================================================================
# Farscape Enterprise Sync Script (Non-Interactive / CI-Ready)
# Function: Automated, Secure, Token-Based Git Sync
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# 1. Load Environment Variables
# ------------------------------------------------------------------------------

ENV_FILE=".env.dev"

if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# ------------------------------------------------------------------------------
# 2. Input Handling (Args > Env > Defaults)
# ------------------------------------------------------------------------------

TARGET_BRANCH="${1:-${TARGET_BRANCH:-main}}"
COMMIT_MSG="${2:-${COMMIT_MSG:-"auto: sync $(date +'%Y-%m-%d %H:%M')"}}"

LOG_FILE="/var/log/farscape/sync_$(date +'%Y%m').log"

# ------------------------------------------------------------------------------
# 3. Pre-flight Checks
# ------------------------------------------------------------------------------

# Git repo check
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "❌ Not inside a Git repository"
    exit 1
}

# Token check (for HTTPS)
if ! git remote get-url origin | grep -q "^git@"; then
    [[ -z "${GITHUB_TOKEN:-}" ]] && {
        echo "❌ GITHUB_TOKEN not found (required for HTTPS)"
        exit 1
    }
fi

# Logging setup
sudo mkdir -p "$(dirname "$LOG_FILE")"
sudo chmod 750 "$(dirname "$LOG_FILE")"

# ------------------------------------------------------------------------------
# 4. Remote & Branch Setup
# ------------------------------------------------------------------------------

REMOTE_URL=$(git remote get-url origin)

# Configure token auth if HTTPS
if [[ "$REMOTE_URL" =~ ^https://github.com/ ]]; then
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
