#!/bin/bash
# Version: 1.4.0
# Description: Enterprise-grade GitHub repo manager with Create, Delete, Rename, CI, Dry-Run, Validation, and Retry.

set -e
set -o pipefail

# ---------------- Logging ----------------
log_info()  { echo "[INFO]  $(date +'%Y-%m-%dT%H:%M:%S') $1"; }
log_warn()  { echo "[WARN]  $(date +'%Y-%m-%dT%H:%M:%S') $1"; }
log_error() { echo "[ERROR] $(date +'%Y-%m-%dT%H:%M:%S') $1" >&2; }

# ---------------- Error Handler ----------------
cleanup() {
    local code=$?
    if [ $code -ne 0 ]; then
        log_error "Command '$BASH_COMMAND' failed (exit=$code)"
    fi
}
trap cleanup EXIT

# ---------------- Help ----------------
usage() {
    echo "Usage: $0 -d <dir> -n <name> -e <env_file> [-v visibility] [-o org] [--ci] [--dry-run] [--rename <new_name>]"
    echo ""
    echo "Options:"
    echo "  -d <dir>          Target directory (required)"
    echo "  -n <name>         Repository name (required)"
    echo "  -e <env_file>     Environment file path (required)"
    echo "  -v <visibility>   public | private | internal (default: public)"
    echo "  -o <org>          GitHub organization name"
    echo "  --ci              Enable CI mode"
    echo "  --dry-run         Show what would be done without executing"
    echo "  --rename <name>   Rename existing repository to new name"
    exit 1
}

# ---------------- Defaults ----------------
VISIBILITY="public"
CI_MODE=false
DRY_RUN=false
ORG=""
RENAME_TO=""

# ---------------- Args ----------------
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d) TARGET_DIR="$2"; shift ;;
        -n) REPO_NAME="$2"; shift ;;
        -e) ENV_PATH="$2"; shift ;;
        -v) VISIBILITY="$2"; shift ;;
        -o) ORG="$2"; shift ;;
        --ci) CI_MODE=true ;;
        --dry-run) DRY_RUN=true ;;
        --rename) RENAME_TO="$2"; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# ---------------- Validation ----------------
[[ -z "$TARGET_DIR" || -z "$REPO_NAME" || -z "$ENV_PATH" ]] && usage
[[ ! "$VISIBILITY" =~ ^(public|private|internal)$ ]] && { log_error "Invalid visibility"; exit 1; }
[[ ! -d "$TARGET_DIR" ]] && { log_error "Directory not found: $TARGET_DIR"; exit 1; }

# ---------------- Load Env ----------------
if [[ -f "$ENV_PATH" ]]; then
    set -a
    source "$ENV_PATH"
    set +a
else
    log_error "Env file not found: $ENV_PATH"
    exit 1
fi

# ---------------- Preflight ----------------
check_system() {

    # GH CLI
    command -v gh >/dev/null || { log_error "gh CLI not installed. Run 01-system-setup.sh first."; exit 1; }

    local gh_version
    gh_version=$(gh --version | head -n1 | awk '{print $3}')
    log_info "Using gh $gh_version"

    # Git Repo
    [[ -d "$TARGET_DIR/.git" ]] || { log_error "Not a git repository. Run 03-init-git-repo.sh first."; exit 1; }

    # Auth - Auto authenticate if GITHUB_TOKEN is available
    if ! gh auth status &>/dev/null; then
        log_info "gh CLI not authenticated. Attempting auto-authentication..."

        if [[ -n "$GITHUB_TOKEN" ]]; then
            log_info "Authenticating with GITHUB_TOKEN from env file..."
            echo "$GITHUB_TOKEN" | gh auth login --with-token

            if gh auth status &>/dev/null; then
                log_info "GitHub CLI authenticated successfully"
            else
                log_error "GitHub authentication failed. Check your GITHUB_TOKEN."
                exit 1
            fi
        else
            log_error "GITHUB_TOKEN not found in env file. Cannot authenticate."
            exit 1
        fi
    else
        log_info "GitHub CLI already authenticated"
    fi
}

# ---------------- Retry Wrapper ----------------
retry() {
    local retries=3
    local count=0

    until "$@"; do
        exit_code=$?
        count=$((count + 1))

        if [ $count -ge $retries ]; then
            return $exit_code
        fi

        log_warn "Retry $count/$retries..."
        sleep 2
    done
}

# ---------------- Main ----------------
check_system

OWNER_PATH="$REPO_NAME"
[[ -n "$ORG" ]] && OWNER_PATH="$ORG/$REPO_NAME"

cd "$TARGET_DIR"

# ---------------- Rename Repository ----------------
if [[ -n "$RENAME_TO" ]]; then
    NEW_OWNER_PATH="$RENAME_TO"
    [[ -n "$ORG" ]] && NEW_OWNER_PATH="$ORG/$RENAME_TO"

    if ! gh repo view "$OWNER_PATH" &>/dev/null; then
        log_error "Source repository not found: $OWNER_PATH"
        exit 1
    fi

    if gh repo view "$NEW_OWNER_PATH" &>/dev/null; then
        log_error "Target repository already exists: $NEW_OWNER_PATH"
        exit 1
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would rename $OWNER_PATH to $NEW_OWNER_PATH"
        exit 0
    fi

    log_info "Renaming repository: $OWNER_PATH -> $NEW_OWNER_PATH"
    gh repo rename "$RENAME_TO" --repo "$OWNER_PATH" --yes

    # Update git remote
    git remote set-url origin "https://github.com/$NEW_OWNER_PATH.git"
    log_info "Repository renamed: https://github.com/$NEW_OWNER_PATH"
    exit 0
fi

# Idempotency
if gh repo view "$OWNER_PATH" &>/dev/null; then
    log_info "Repository already exists: $OWNER_PATH"
    exit 0
fi

# Dry Run
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would create $VISIBILITY repo: $OWNER_PATH"
    exit 0
fi

# Create Repo
log_info "Creating repository: $OWNER_PATH"

retry gh repo create "$OWNER_PATH" \
    --"$VISIBILITY" \
    --source=. \
    --remote=origin \
    --push

log_info "Repository live: https://github.com/$OWNER_PATH"
