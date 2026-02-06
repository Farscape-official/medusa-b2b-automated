#!/usr/bin/env bash
set -euo pipefail

# =============================================
# Farscape Context Generator
# =============================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS_DIR="$ROOT_DIR/docs"
SOURCE_FILE="$DOCS_DIR/project-context.md"
OUT_DIR="$DOCS_DIR/context"

LOG_PREFIX="[context-gen]"

log() {
  echo "$LOG_PREFIX $1"
}

# ---------------------------------------------
# Validation
# ---------------------------------------------

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "ERROR: $SOURCE_FILE not found"
  exit 1
fi

mkdir -p "$OUT_DIR"

log "Using source: $SOURCE_FILE"
log "Output dir:  $OUT_DIR"

# ---------------------------------------------
# Helper: Extract Section
# ---------------------------------------------
extract_section() {
  local start="$1"
  local end="$2"
  local out="$3"

  awk "
    /^## $start/ {flag=1}
    /^## $end/   {flag=0}
    flag
  " "$SOURCE_FILE" > "$OUT_DIR/$out"
}

# ---------------------------------------------
# Generate Files
# ---------------------------------------------

log "Generating context files..."

# 00 Overview (Top section before TOC)
awk '
  NR==1,/^## Environment/
' "$SOURCE_FILE" > "$OUT_DIR/00-project-overview.md"

extract_section "Environment & Setup Questions" "Architecture Decisions" "01-environment.md"

extract_section "Architecture Decisions" "Domain & Network Configuration" "02-architecture.md"

extract_section "Script Architecture" "Environment Variables Structure" "04-scripts.md"

extract_section "Environment Variables Structure" "Port Mapping Strategy" "06-env-variables.md"

extract_section "Domain & Network Configuration" "Script Architecture" "07-networking.md"

extract_section "Initial Setup Workflow" "Pending Decisions" "08-workflows.md"

extract_section "Pending Decisions" "Next Steps" "10-decisions.md"

# ---------------------------------------------
# AI Core
# ---------------------------------------------

cat > "$OUT_DIR/AI_CORE.md" <<'EOF'
# Farscape AI Core Rules

- Scripts are source of truth
- No manual fixes in code
- No hardcoded paths
- Dev/Prod always separated
- Secrets never committed
- Docker-first deployment
- Idempotent automation only
- All failures require script updates
EOF

# ---------------------------------------------
# Index
# ---------------------------------------------

cat > "$OUT_DIR/README.md" <<EOF
# Farscape Context Index

Generated automatically. Do not edit manually.

| Area | File |
|------|------|
| Overview | 00-project-overview.md |
| Environment | 01-environment.md |
| Architecture | 02-architecture.md |
| Scripts | 04-scripts.md |
| Env Vars | 06-env-variables.md |
| Network | 07-networking.md |
| Workflow | 08-workflows.md |
| Decisions | 10-decisions.md |
| AI Rules | AI_CORE.md |
EOF

log "Context generation complete."
