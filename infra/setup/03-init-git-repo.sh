#!/bin/bash
# Version: 1.3.0
# Description: Portable, secure Git initialization with signal trapping and getopts.

set -e
set -o pipefail

# --- Centralized Error & Signal Handler ---
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "[$(date +'%Y-%m-%dT%H:%M:%S')] [CRITICAL] Script failed at step: $BASH_COMMAND" >&2
    fi
}
trap cleanup EXIT

# --- Defaults ---
LOG_FILE="$HOME/automation_git.log"
TARGET_DIR="$HOME/farscape"
ENV_PATH="$HOME/farscape/env/.env.dev"
VISIBILITY="public"
REMOTE_URL=""

# --- Help Menu ---
usage() {
    echo "Usage: $0 [-n repo_name] [-e env_file] [-v visibility] [-r remote_url]"
    exit 1
}

# --- Parse Arguments (getopts) ---
while getopts "n:e:v:r:h" opt; do
    case $opt in
        n) TARGET_DIR="$HOME/$OPTARG" ;;
        e) ENV_PATH="$OPTARG" ;;
        v) VISIBILITY="$OPTARG" ;;
        r) REMOTE_URL="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# --- Load Environment Safely ---
if [[ -f "$ENV_PATH" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_PATH"
    set +a
else
    echo "[ERROR] Env file not found: $ENV_PATH" && exit 1
fi

# --- Pre-flight Logic ---
[[ -d "$TARGET_DIR/.git" ]] && { echo "[SKIP] Git already initialized in $TARGET_DIR. Exiting safely."; exit 0; }

# --- Execution ---
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

git init

# Identity check (from .env or shell env)
git config user.name "${GIT_USER:-"Unknown User"}"
git config user.email "${GIT_EMAIL:-"unknown@internal.com"}"

# Standard .gitignore
cat <<EOF > .gitignore
.env*
!.env.example
node_modules/
dist/
*.log
EOF

# Remote URL handling
if [[ -n "$REMOTE_URL" ]]; then
    git remote add origin "$REMOTE_URL"
fi

git add .
git commit -m "chore: initial project structure v1.3.0"

echo "[SUCCESS] Repository initialized at $TARGET_DIR"
