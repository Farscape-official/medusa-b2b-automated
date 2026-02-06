#!/bin/bash
# ==========================================
# File: 06-configure-apps.sh
# Version: 1.3.3
# Purpose: Configure Medusa backend, worker, and storefront
# ==========================================

set -euo pipefail

# ---------------- RUNTIME CONTEXT ----------------

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

APPS_DIR="$PROJECT_ROOT/apps"
BACKEND_PATH="$APPS_DIR/medusa-backend"
FRONTEND_PATH="$APPS_DIR/storefront"
WORKER_PATH="$APPS_DIR/medusa-worker"

SECRETS_FILE="${SECRETS_FILE:-$PROJECT_ROOT/env/prod.env}"

LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/06-configure-apps.log"

BACKUP_DIR="$PROJECT_ROOT/backups/config-$(date +%F-%H%M%S)"

BRAND_NAME="${BRAND_NAME:-Farscape B2B}"
APP_AUTHOR="${APP_AUTHOR:-Farscape}"

# ---------------- LOGGING ----------------

mkdir -p "$LOG_DIR" "$BACKUP_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ---------------- ROLLBACK ----------------

rollback() {
  log "ERROR detected. Rolling back configuration..."

  for meta in "$BACKUP_DIR"/*.meta; do
    [[ -f "$meta" ]] || continue
    src="$(cat "$meta")"
    file="$(basename "$meta" .meta)"
    cp "$BACKUP_DIR/$file" "$src"
  done

  log "Rollback completed"
  exit 1
}

trap rollback ERR

# ---------------- PRECHECK ----------------

if [[ ! -f "$SECRETS_FILE" ]]; then
  if [[ -f "$PROJECT_ROOT/env/.env.dev" ]]; then
    SECRETS_FILE="$PROJECT_ROOT/env/.env.dev"
    log "Using fallback secrets file: env/.env.dev"
  else
    log "Secrets file not found"
    exit 1
  fi
fi

command -v jq >/dev/null || { log "jq missing"; exit 1; }

# ---------------- LOAD SECRETS ----------------

set -o allexport
source "$SECRETS_FILE"
set +o allexport

log "Secrets loaded"

# ---------------- BACKUP ----------------

backup_file() {
  local src="$1"
  local name="$2"
  [[ -f "$src" ]] || return
  cp "$src" "$BACKUP_DIR/$name"
  echo "$src" > "$BACKUP_DIR/$name.meta"
}

backup_file "$BACKEND_PATH/package.json" backend-package.json
backup_file "$FRONTEND_PATH/package.json" storefront-package.json
backup_file "$WORKER_PATH/package.json" worker-package.json
backup_file "$BACKEND_PATH/medusa-config.ts" backend-medusa-config.ts

# ---------------- PACKAGE.JSON BRANDING ----------------

update_package_json() {
  local target="$1/package.json"
  local suffix="$2"
  [[ -f "$target" ]] || return

  jq \
    --arg name "$BRAND_NAME-$suffix" \
    --arg author "$APP_AUTHOR" \
    '
    .name = ($name | ascii_downcase | gsub(" "; "-"))
    | .author = $author
    ' "$target" > "$target.tmp"

  mv "$target.tmp" "$target"
}

update_package_json "$BACKEND_PATH" "backend"
update_package_json "$FRONTEND_PATH" "storefront"
update_package_json "$WORKER_PATH" "worker"

# ---------------- ENV MERGE ----------------

merge_env() {
  local app_path="$1"
  local env_file="$app_path/.env"

  touch "$env_file"
  chmod 600 "$env_file"

  while IFS='=' read -r key _; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    if ! grep -qF "$key=" "$env_file"; then
      echo "$key=${!key:-}" >> "$env_file"
    fi
  done < <(env)
}

merge_env "$BACKEND_PATH"
merge_env "$FRONTEND_PATH"
merge_env "$WORKER_PATH"

# ---------------- MEDUSA MODULE REGISTRATION ----------------

MEDUSA_CONFIG="$BACKEND_PATH/medusa-config.ts"

if [[ -f "$MEDUSA_CONFIG" ]] && ! grep -qF "farscape:" "$MEDUSA_CONFIG"; then
  cp "$MEDUSA_CONFIG" "$MEDUSA_CONFIG.bak"

  awk '
  /modules:[[:space:]]*{/ && !done {
    print
    print "    farscape: {"
    print "      resolve: \"./src/modules/farscape\","
    print "      options: {}"
    print "    },"
    done=1
    next
  }
  { print }
  ' "$MEDUSA_CONFIG.bak" > "$MEDUSA_CONFIG"

  rm "$MEDUSA_CONFIG.bak"
fi

# ---------------- DEPENDENCY SAFETY ----------------

ensure_node_modules() {
  local path="$1"
  if [[ -d "$path" && ! -d "$path/node_modules" ]]; then
    log "Installing dependencies in $(basename "$path")"
    (cd "$path" && npm install --no-audit --no-fund --legacy-peer-deps)
  fi
}

ensure_node_modules "$BACKEND_PATH"
ensure_node_modules "$WORKER_PATH"

# ---------------- SMOKE TEST ----------------

TS_PATH="$BACKEND_PATH/node_modules/typescript"

if [[ -d "$TS_PATH" ]]; then
  node -e "require('$TS_PATH');require('fs').readFileSync('$MEDUSA_CONFIG')" \
    || { log "Smoke test failed"; exit 1; }
else
  log "TypeScript not installed, skipping TS smoke test"
fi

# ---------------- FINAL ----------------

log "06-configure-apps.sh completed successfully"
exit 0

