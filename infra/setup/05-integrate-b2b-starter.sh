#!/bin/bash

# ==============================================================================
# Script Name: 05-integrate-b2b-starter.sh
# Strategy: Robust transplant of Medusa B2B starter into Farscape monorepo
# Version: 1.1 (Mandatory Fixes Applied)
# ==============================================================================

set -e
set -o pipefail

# ------------------------------------------------------------------------------
# 1. Auto-detect Project Root (No Hardcoding)
# ------------------------------------------------------------------------------
BASE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
APPS_DIR="$BASE_DIR/apps"

TEMP_DIR="/tmp/medusa_b2b_clone"
BACKUP_DIR="/tmp/farscape_apps_backup_$(date +%Y%m%d_%H%M%S)"

STARTER_REPO="https://github.com/medusajs/b2b-starter-medusa"

# ------------------------------------------------------------------------------
# 2. Logging
# ------------------------------------------------------------------------------
LOG_FILE="$BASE_DIR/logs/bootstrap.log"
mkdir -p "$(dirname "$LOG_FILE")"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "-------------------------------------------------------"
echo "Starting Script 05: B2B Starter Integration"
echo "Timestamp: $(date -Iseconds)"
echo "-------------------------------------------------------"

# ------------------------------------------------------------------------------
# 3. Failure Rollback
# ------------------------------------------------------------------------------
cleanup_on_failure() {
    echo "CRITICAL ERROR: Integration failed."

    if [ -d "$BACKUP_DIR" ]; then
        echo "Restoring apps directory from backup..."
        rm -rf "$APPS_DIR"
        mv "$BACKUP_DIR" "$APPS_DIR"
    fi

    rm -rf "$TEMP_DIR"

    echo "Rollback completed."
    exit 1
}

trap cleanup_on_failure ERR

# ------------------------------------------------------------------------------
# 4. Pre-flight Validation
# ------------------------------------------------------------------------------
if [ ! -d "$APPS_DIR" ]; then
    echo "ERROR: apps directory not found: $APPS_DIR"
    exit 1
fi

command -v git >/dev/null 2>&1 || {
    echo "ERROR: git is not installed."
    exit 1
}

# ------------------------------------------------------------------------------
# 5. Backup Existing Apps
# ------------------------------------------------------------------------------
echo "Backing up existing apps directory..."
cp -r "$APPS_DIR" "$BACKUP_DIR"

# ------------------------------------------------------------------------------
# 6. Clone Starter Repository
# ------------------------------------------------------------------------------
echo "Cloning Medusa B2B starter..."

rm -rf "$TEMP_DIR"

git clone --depth 1 "$STARTER_REPO" "$TEMP_DIR"

rm -rf "$TEMP_DIR/.git"

# ------------------------------------------------------------------------------
# 7. Validate Clone Integrity
# ------------------------------------------------------------------------------
echo "Validating cloned repository..."

REQUIRED_STARTER_FILES=(
    "$TEMP_DIR/backend"
    "$TEMP_DIR/storefront"
)

for ITEM in "${REQUIRED_STARTER_FILES[@]}"; do
    if [ ! -e "$ITEM" ]; then
        echo "Validation failed: Missing $ITEM"
        false
    fi
done

# ------------------------------------------------------------------------------
# 8. Prepare Target Directories (FIXED)
# ------------------------------------------------------------------------------
echo "Preparing target directories..."

mkdir -p \
    "$APPS_DIR/medusa-backend" \
    "$APPS_DIR/storefront" \
    "$APPS_DIR/medusa-worker"

rm -rf "$APPS_DIR/medusa-backend"/*
rm -rf "$APPS_DIR/storefront"/*
rm -rf "$APPS_DIR/medusa-worker"/*

# ------------------------------------------------------------------------------
# 9. Transplant Backend
# ------------------------------------------------------------------------------
echo "Integrating backend..."

cp -r "$TEMP_DIR/backend/." "$APPS_DIR/medusa-backend/"

# ------------------------------------------------------------------------------
# 10. Transplant Storefront
# ------------------------------------------------------------------------------
echo "Integrating storefront..."

cp -r "$TEMP_DIR/storefront/." "$APPS_DIR/storefront/"

# ------------------------------------------------------------------------------
# 11. Initialize Worker (Minimal, Safe)
# ------------------------------------------------------------------------------
echo "Initializing medusa-worker..."

cp "$APPS_DIR/medusa-backend/package.json" \
   "$APPS_DIR/medusa-worker/package.json"

mkdir -p "$APPS_DIR/medusa-worker/src"

cat > "$APPS_DIR/medusa-worker/src/index.ts" <<EOF
// Auto-generated worker entrypoint
export {};
EOF

# ------------------------------------------------------------------------------
# 12. Inject Custom B2B Module Stubs
# ------------------------------------------------------------------------------
echo "Injecting custom B2B modules..."

MODULE_PATH="$APPS_DIR/medusa-backend/src/modules"

mkdir -p "$MODULE_PATH"/{credit,supplier,pricing,negotiation}

mkdir -p \
  "$APPS_DIR/medusa-backend/src/api/routes/hooks/razorpay"

# ------------------------------------------------------------------------------
# 13. Update .gitignore (Append Only)
# ------------------------------------------------------------------------------
echo "Updating .gitignore..."

GITIGNORE="$BASE_DIR/.gitignore"

touch "$GITIGNORE"

append_gitignore() {
    grep -qxF "$1" "$GITIGNORE" || echo "$1" >> "$GITIGNORE"
}

append_gitignore "/node_modules"
append_gitignore ".env*"
append_gitignore ".medusa/"
append_gitignore "logs/"

# ------------------------------------------------------------------------------
# 14. Final Integrity Check
# ------------------------------------------------------------------------------
echo "Running final integrity checks..."

REQUIRED_FILES=(
    "$APPS_DIR/medusa-backend/package.json"
    "$APPS_DIR/medusa-backend/medusa-config.ts"
    "$APPS_DIR/storefront/package.json"
    "$APPS_DIR/medusa-worker/package.json"
)

for FILE in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo "Integrity check failed: $FILE not found"
        false
    fi
done

# ------------------------------------------------------------------------------
# 15. Cleanup
# ------------------------------------------------------------------------------
echo "Cleaning up temporary files..."

rm -rf "$TEMP_DIR"
rm -rf "$BACKUP_DIR"

chown -R "$USER:$USER" "$APPS_DIR" || true

# ------------------------------------------------------------------------------
# 16. Success
# ------------------------------------------------------------------------------
echo "-------------------------------------------------------"
echo "SUCCESS: B2B Starter integrated successfully."
echo "Log file: $LOG_FILE"
echo "-------------------------------------------------------"
