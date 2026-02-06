#!/bin/bash
# ==============================================================================
# File: 07-install-dependencies.sh
# Version: 3.0.0
# Responsibility: DYNAMIC MONOREPO DEPENDENCY RESOLUTION
# Strict Rule: NO DOWNSTREAM SCRIPT MAY RUN NPM INSTALL AFTER THIS.
# ==============================================================================

set -euo pipefail
set -o nounset

# ---------------- DYNAMIC ENVIRONMENT ----------------
# Derive root from the script location to eliminate hardcoded paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="/var/log/farscape"
LOG_FILE="$LOG_DIR/dependency-resolution.log"

# ---------------- AUDIT LOGGING ----------------
mkdir -p "$LOG_DIR"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Trap for audit completeness on failure
cleanup_on_fail() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "FATAL: Script failed with exit code $exit_code. Dependency graph may be unstable."
    fi
}
trap cleanup_on_fail EXIT

fail() {
    log "ERROR: $1"
    exit 1
}

# ---------------- PRE-FLIGHT CHECKS ----------------
cd "$PROJECT_ROOT"
log "Context: Working in $PROJECT_ROOT"

# Validate critical files
[[ -f "package.json" ]] || fail "Root package.json missing."
[[ -f "package-lock.json" ]] || fail "Root package-lock.json missing. AUTHORITY LOCK REQUIRED."

# Prevent multiple lockfile authority conflicts
[[ ! -f "yarn.lock" && ! -f "pnpm-lock.yaml" ]] || fail "Multiple lockfiles detected. NPM is the sole authority."

# Validate workspace configuration
jq -e '.workspaces' package.json >/dev/null || fail "Workspaces key missing in package.json."

# ---------------- RESOLUTION STRATEGY ----------------
log "NPM Version: $(npm -v)"
log "Node Version: $(node -v)"

log "Executing workspace-aware resolution (npm install)..."

# RISK ACKNOWLEDGMENT: --legacy-peer-deps is mandatory to bridge Medusa 2.x
# core modules with Next.js 15 peer requirements during this development phase.
npm install --legacy-peer-deps --no-audit --no-fund || fail "NPM resolution failed."

# ---------------- POST-INSTALL VALIDATION (WORKSPACE-AWARE) ----------------
log "Validating npm workspace resolution..."

# 1. Root node_modules must exist
if [[ ! -d "node_modules" ]]; then
    fail "Root node_modules directory missing. Dependency resolution failed."
fi

# 2. npm must resolve all workspaces cleanly (hoisting-aware)
if ! npm ls --workspaces --depth=0 >/dev/null 2>&1; then
    fail "npm workspace resolution failed. Broken or unresolved dependency graph."
fi

# 3. Validate each workspace is recognized by npm
WORKSPACES=$(jq -r '.workspaces[]' package.json)
for ws in $WORKSPACES; do
    if ! npm ls --workspace "$ws" --depth=0 >/dev/null 2>&1; then
        fail "Workspace dependency resolution failed for: $ws"
    fi
    log "Workspace validated via npm resolution: $ws"
done

log "Workspace-aware dependency validation passed (hoisted dependencies expected)."

# ---------------- STAGE LOCKFILE DRIFT ----------------
if ! git diff --quiet package-lock.json 2>/dev/null; then
    git add package-lock.json
    log "Lockfile updated and staged. Commit after this script completes."
fi

# ---------------- OUTPUT CONTRACT ----------------
log "PATH value at completion: $PATH"
echo "------------------------------------------"
echo "      DEPENDENCY RESOLUTION COMPLETE      "
echo "      PROJECT ROOT: $PROJECT_ROOT         "
echo "      MODE: WORKSPACE AUTHORITY           "
echo "------------------------------------------"
log "07-install-dependencies.sh completed successfully."

exit 0