#!/bin/bash

# ==============================================================================
# Farscape Advanced Dynamic Sync Script
# Function: Secure, Branch-Aware, and Idempotent Code Synchronization
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# 1. Pre-flight Git & Auth Checks
[[ $(git rev-parse --is-inside-work-tree) == "true" ]] || { echo "❌ Not a git repo"; exit 1; } [cite: 574]

REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "none")
[[ "$REMOTE_URL" == "none" ]] && { echo "❌ No origin remote"; exit 1; }

# 2. Dynamic Logging Setup
LOG_FILE="/var/log/farscape/sync_$(date +'%Y%m').log"
sudo mkdir -p "$(dirname "$LOG_FILE")"
sudo chmod 777 "$(dirname "$LOG_FILE")"

# 3. Interactive Branch & Remote Validation
echo "🔍 Fetching latest remote state..."
git fetch origin --quiet

# List local and remote branches for user context
echo "--- Existing Branches ---"
git branch -a | grep -v "remotes/origin/HEAD"
echo "-------------------------"

# Get Target Branch from User
read -p "Enter target branch name: " TARGET_BRANCH
[[ -z "$TARGET_BRANCH" ]] && { echo "❌ Branch name cannot be empty"; exit 1; }

# Check if branch exists on remote to prevent orphan pushes
if ! git ls-remote --heads origin "$TARGET_BRANCH" | grep -q "$TARGET_BRANCH"; then
    read -p "⚠️ Branch '$TARGET_BRANCH' does not exist on remote. Create it? (y/n): " CREATE_CONFIRM
    [[ "$CREATE_CONFIRM" != "y" ]] && { echo "🛑 Aborted"; exit 1; }
fi

# Switch branch if necessary
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
if [[ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]]; then
    echo "🔄 Switching from $CURRENT_BRANCH to $TARGET_BRANCH..."
    git checkout -b "$TARGET_BRANCH" 2>/dev/null || git checkout "$TARGET_BRANCH"
fi

# 4. Commit Logic
read -p "Enter commit message: " COMMIT_MSG
[[ -z "$COMMIT_MSG" ]] && COMMIT_MSG="auto: sync $(date +'%Y-%m-%d %H:%M')"

# 5. Execution with Pipefail Protection
{
    echo "--- Sync Operation Started: $(date) ---"
    
    # Auth Check (SSH vs HTTPS)
    if [[ "$REMOTE_URL" == git@* ]]; then
        ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" || true
    fi

    echo "📦 Staging tracked changes (git add -u)..."
    git add -u 

    echo "💾 Committing changes..."
    # Only commit if there are changes to avoid exit 1
    if ! git diff-index --quiet HEAD --; then
        git commit -m "$COMMIT_MSG"
    else
        echo "ℹ️ No changes to commit."
    fi

    echo "🚀 Pushing to origin/$TARGET_BRANCH..."
    # Ensure upstream is set to prevent orphan push mistakes
    git push -u origin "$TARGET_BRANCH"

    echo "✅ Successfully synced to: $(git remote get-url origin)"
    echo "--- Sync Operation Completed: $(date) ---"
} 2>&1 | tee -a "$LOG_FILE"
