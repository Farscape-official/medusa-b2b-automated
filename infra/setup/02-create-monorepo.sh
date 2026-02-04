#!/bin/bash

################################################################################
# Farscape B2B Platform - Create Monorepo Structure
################################################################################
# Purpose: Scaffold complete monorepo structure (infrastructure only)
# Author: Gaurav (gaurav@farscape.io)
# Organization: Farscape-official
# 
# What this script does:
# 1. Creates complete folder structure (/root/farscape)
# 2. Creates placeholder directories for apps (storefront/backend to be scaffolded separately)
# 3. Creates Docker configurations (dev + prod)
# 4. Creates all automation scripts (placeholders)
# 5. Creates environment file templates
# 6. Creates Nginx configs
# 7. Sets up proper permissions
#
# What this script DOES NOT do:
# - Does NOT scaffold Next.js storefront (done separately)
# - Does NOT scaffold Medusa backend (done separately)
#
# Features:
# - Idempotent (can run multiple times safely)
# - State tracking (skips completed steps)
# - Automatic rollback on failure
# - Dry-run mode support
#
# Requirements:
# - Script #1 completed (Docker, Node.js installed)
# - Run as root
#
# Usage:
#   bash 02-create-monorepo.sh
#   DRY_RUN=true bash 02-create-monorepo.sh  # Test mode
#
################################################################################

set -euo pipefail

# Fix TERM variable for non-interactive environments
export TERM="${TERM:-xterm}"

################################################################################
# CONFIGURATION
################################################################################

# Project configuration
PROJECT_ROOT="/root/farscape"
PACKAGE_MANAGER="npm"
OWNER="root"
GROUP="root"

# Logging
LOG_DIR="/var/log/farscape"
LOG_FILE="${LOG_DIR}/create-monorepo.log"
STATE_FILE="${LOG_DIR}/create-monorepo-state.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Backup location
BACKUP_DIR="/tmp/farscape-monorepo-backup-$$"

# Dry run mode
DRY_RUN="${DRY_RUN:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

################################################################################
# HELPER FUNCTIONS
################################################################################

log() {
    local level=$1
    shift
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $*" | tee -a "${LOG_FILE}"
}

info() {
    echo -e "${GREEN}[INFO]${NC} $*" | tee -a "${LOG_FILE}"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "${LOG_FILE}"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}"
}

success() {
    echo -e "${BLUE}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}"
}

step() {
    echo -e "${CYAN}[STEP]${NC} $*" | tee -a "${LOG_FILE}"
}

# State tracking functions
mark_step_complete() {
    echo "$1:completed:$(date)" >> "$STATE_FILE"
}

is_step_complete() {
    grep -q "^$1:completed" "$STATE_FILE" 2>/dev/null
}

# Execute with dry-run support
execute() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${CYAN}[DRY-RUN]${NC} Would execute: $*"
        return 0
    else
        eval "$*"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
}

# Create backup of existing directory
create_backup() {
    if [[ -d "$PROJECT_ROOT" ]]; then
        warn "Existing project directory found at $PROJECT_ROOT"
        info "Creating backup at $BACKUP_DIR"
        execute "mkdir -p $BACKUP_DIR"
        execute "cp -r $PROJECT_ROOT/* $BACKUP_DIR/ 2>/dev/null || true"
        success "Backup created"
    fi
}

# Rollback on error
rollback_on_error() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        error "Script failed with exit code: $exit_code"
        error "Rolling back changes..."
        
        if [[ -d "$BACKUP_DIR" ]] && [[ -n "$(ls -A $BACKUP_DIR 2>/dev/null)" ]]; then
            info "Restoring from backup..."
            rm -rf "$PROJECT_ROOT"
            mkdir -p "$PROJECT_ROOT"
            cp -r "$BACKUP_DIR"/* "$PROJECT_ROOT/"
            success "Backup restored"
        else
            warn "No backup found or backup empty, removing incomplete structure..."
            rm -rf "$PROJECT_ROOT"
        fi
        
        # Clean up backup
        rm -rf "$BACKUP_DIR"
        
        error "Rollback complete. You can safely re-run the script."
        exit $exit_code
    fi
    
    # Clean up backup on success
    if [[ -d "$BACKUP_DIR" ]]; then
        rm -rf "$BACKUP_DIR"
    fi
}

# Register cleanup
trap rollback_on_error EXIT

################################################################################
# VALIDATION FUNCTIONS
################################################################################

validate_prerequisites() {
    step "Validating prerequisites..."
    
    # Check Node.js
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js not found. Please run script #1 first."
        exit 1
    fi
    
    # Check npm
    if ! command -v npm >/dev/null 2>&1; then
        error "npm not found. Please run script #1 first."
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker not found. Please run script #1 first."
        exit 1
    fi
    
    success "All prerequisites validated"
}

################################################################################
# DIRECTORY CREATION FUNCTIONS
################################################################################

create_root_structure() {
    if is_step_complete "create_root_structure"; then
        info "Root structure already created, skipping..."
        return 0
    fi
    
    step "Creating root directory structure..."
    
    execute "mkdir -p $PROJECT_ROOT"
    
    # Main directories
    local dirs=(
        "apps"
        "infra"
        "scripts"
        "env"
        "services"
        "docs"
    )
    
    for dir in "${dirs[@]}"; do
        execute "mkdir -p $PROJECT_ROOT/$dir"
    done
    
    mark_step_complete "create_root_structure"
    success "Root structure created"
}

create_apps_structure() {
    if is_step_complete "create_apps_structure"; then
        info "Apps structure already created, skipping..."
        return 0
    fi
    
    step "Creating apps directory structure (placeholders only)..."
    
    # Storefront directory (empty, to be scaffolded separately)
    execute "mkdir -p $PROJECT_ROOT/apps/storefront"
    
    # Medusa backend directory (empty, to be scaffolded separately)
    execute "mkdir -p $PROJECT_ROOT/apps/medusa-backend"
    
    # Medusa worker directory (empty, to be scaffolded separately)
    execute "mkdir -p $PROJECT_ROOT/apps/medusa-worker"
    
    mark_step_complete "create_apps_structure"
    success "Apps directory structure created (placeholders)"
}

create_infra_structure() {
    if is_step_complete "create_infra_structure"; then
        info "Infra structure already created, skipping..."
        return 0
    fi
    
    step "Creating infrastructure directory structure..."
    
    # Infra subdirectories
    execute "mkdir -p $PROJECT_ROOT/infra/{setup,docker,compose,nginx,scripts}"
    execute "mkdir -p $PROJECT_ROOT/infra/nginx/{sites,ssl,conf.d}"
    
    mark_step_complete "create_infra_structure"
    success "Infra structure created"
}

create_scripts_structure() {
    if is_step_complete "create_scripts_structure"; then
        info "Scripts structure already created, skipping..."
        return 0
    fi
    
    step "Creating scripts directory structure..."
    
    # Scripts subdirectories
    execute "mkdir -p $PROJECT_ROOT/scripts/{dev,prod,shared}"
    
    mark_step_complete "create_scripts_structure"
    success "Scripts structure created"
}

create_services_structure() {
    if is_step_complete "create_services_structure"; then
        info "Services structure already created, skipping..."
        return 0
    fi
    
    step "Creating services directory structure..."
    
    # Services subdirectories
    execute "mkdir -p $PROJECT_ROOT/services/{minio,postgres}"
    
    mark_step_complete "create_services_structure"
    success "Services structure created"
}

################################################################################
# FILE CREATION FUNCTIONS
################################################################################

create_root_package_json() {
    if is_step_complete "create_root_package_json"; then
        info "Root package.json already created, skipping..."
        return 0
    fi
    
    step "Creating root package.json..."
    
    cat > "$PROJECT_ROOT/package.json" <<'EOF'
{
  "name": "farscape",
  "version": "1.0.0",
  "private": true,
  "description": "Farscape B2B Ecommerce Platform",
  "workspaces": [
    "apps/*"
  ],
  "scripts": {
    "dev:storefront": "npm run dev --workspace=apps/storefront",
    "dev:backend": "npm run dev --workspace=apps/medusa-backend",
    "build:all": "npm run build --workspaces",
    "lint": "npm run lint --workspaces",
    "test": "npm run test --workspaces"
  },
  "keywords": ["b2b", "ecommerce", "medusa", "nextjs"],
  "author": "Gaurav <gaurav@farscape.io>",
  "license": "UNLICENSED"
}
EOF
    
    mark_step_complete "create_root_package_json"
    success "Root package.json created"
}

create_app_placeholders() {
    if is_step_complete "create_app_placeholders"; then
        info "App placeholders already created, skipping..."
        return 0
    fi
    
    step "Creating app placeholder README files..."
    
    # Storefront placeholder
    cat > "$PROJECT_ROOT/apps/storefront/README.md" <<'EOF'
# Farscape Storefront

⏳ **Status:** To be scaffolded

## Next Steps

This directory will contain the Next.js 15 storefront.

### Scaffolding Options:

**Option 1: Using Medusa Next.js Starter**
```bash
cd /root/farscape/apps
npx create-medusa-app@latest --with-nextjs-starter storefront
```

**Option 2: Using create-next-app**
```bash
cd /root/farscape/apps
npx create-next-app@latest storefront --typescript --tailwind --app
```

## Planned Stack

- Next.js 15 (App Router)
- React 18
- TypeScript
- Tailwind CSS
- Medusa JS SDK

## Integration with Backend

The storefront will connect to the Medusa backend at:
- **Dev:** `http://localhost:9001`
- **Prod:** `https://api.farscape.in`
EOF
    
    # Medusa backend placeholder
    cat > "$PROJECT_ROOT/apps/medusa-backend/README.md" <<'EOF'
# Farscape Medusa Backend

⏳ **Status:** To be scaffolded

## Next Steps

This directory will contain the Medusa 2.x backend with custom B2B modules.

### Scaffolding Command:

```bash
cd /root/farscape/apps
npx create-medusa-app@latest medusa-backend
```

## Custom B2B Modules (To Be Implemented)

- **Credit Module:** Credit-based checkout and accounting
- **Supplier Module:** Dropship/supplier management
- **Pricing Module:** Volume-based pricing tiers
- **Negotiation Module:** Price negotiation workflow

## Directory Structure (After Scaffolding)

```
medusa-backend/
├── src/
│   ├── modules/
│   │   ├── credit/
│   │   ├── supplier/
│   │   ├── pricing/
│   │   └── negotiation/
│   └── api/
│       └── routes/
│           └── hooks/
│               └── razorpay/
├── medusa-config.js
└── package.json
```

## Integration Points

- **Database:** PostgreSQL via `DATABASE_URL`
- **Cache:** Redis via `REDIS_URL`
- **Storage:** MinIO (S3-compatible)
- **Payments:** Razorpay
EOF
    
    # Medusa worker placeholder
    cat > "$PROJECT_ROOT/apps/medusa-worker/README.md" <<'EOF'
# Farscape Medusa Worker

⏳ **Status:** To be implemented

## Purpose

Background worker for async processing:
- Supplier notifications
- Email sending
- Report generation
- Cleanup tasks

## Implementation

Will be implemented after Medusa backend is set up.
EOF
    
    mark_step_complete "create_app_placeholders"
    success "App placeholder README files created"
}

create_env_files() {
    if is_step_complete "create_env_files"; then
        info "Environment files already created, skipping..."
        return 0
    fi
    
    step "Creating environment file templates..."
    
    # .env.dev
    cat > "$PROJECT_ROOT/env/.env.dev" <<'EOF'
# ============================================
# NODE ENVIRONMENT
# ============================================
NODE_ENV=development

# ============================================
# MEDUSA BACKEND CONFIGURATION
# ============================================
DATABASE_URL=postgresql://medusa_dev:dev_password@postgres-dev:5432/medusa_dev
REDIS_URL=redis://redis-dev:6379
STORE_CORS=http://localhost:3001
ADMIN_CORS=http://localhost:9001

# ============================================
# MINIO (S3-COMPATIBLE OBJECT STORAGE)
# ============================================
MINIO_ENDPOINT=http://minio-dev:9000
MINIO_ACCESS_KEY=dev_access_key_12345
MINIO_SECRET_KEY=dev_secret_key_67890
MINIO_BUCKET=farscape-dev

# ============================================
# RAZORPAY (TEST CREDENTIALS)
# ============================================
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=test_secret_xxxxxxxxxxxxxxxx

# ============================================
# NEXT.JS STOREFRONT
# ============================================
NEXT_PUBLIC_MEDUSA_BACKEND_URL=http://localhost:9001
NEXT_PUBLIC_BASE_URL=http://localhost:3001
EOF
    
    # .env.production.example
    cat > "$PROJECT_ROOT/env/.env.production.example" <<'EOF'
# ============================================
# NODE ENVIRONMENT
# ============================================
NODE_ENV=production

# ============================================
# MEDUSA BACKEND CONFIGURATION
# ============================================
DATABASE_URL=postgresql://medusa_prod:CHANGE_ME@postgres-prod:5432/medusa_prod
REDIS_URL=redis://redis-prod:6379
STORE_CORS=https://store.farscape.in
ADMIN_CORS=https://admin.farscape.in

# ============================================
# MINIO (S3-COMPATIBLE OBJECT STORAGE)
# ============================================
MINIO_ENDPOINT=https://minio.farscape.in
MINIO_ACCESS_KEY=CHANGE_ME
MINIO_SECRET_KEY=CHANGE_ME
MINIO_BUCKET=farscape-prod

# ============================================
# RAZORPAY (LIVE CREDENTIALS)
# ============================================
RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=CHANGE_ME

# ============================================
# NEXT.JS STOREFRONT
# ============================================
NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://api.farscape.in
NEXT_PUBLIC_BASE_URL=https://store.farscape.in

# ============================================
# SECURITY (GENERATE RANDOM STRINGS)
# ============================================
# Generate using: openssl rand -base64 64
JWT_SECRET=GENERATE_RANDOM_64_CHAR_STRING
COOKIE_SECRET=GENERATE_RANDOM_64_CHAR_STRING
EOF
    
    mark_step_complete "create_env_files"
    success "Environment files created"
}

create_docker_files() {
    if is_step_complete "create_docker_files"; then
        info "Docker files already created, skipping..."
        return 0
    fi
    
    step "Creating Docker configuration files..."
    
    # Dockerfile.medusa (will be updated after backend scaffolding)
    cat > "$PROJECT_ROOT/infra/docker/Dockerfile.medusa" <<'EOF'
# Medusa Backend Dockerfile
# To be updated after Medusa backend is scaffolded

FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY apps/medusa-backend/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY apps/medusa-backend .

# Build (if needed)
# RUN npm run build

EXPOSE 9000

CMD ["npm", "start"]
EOF
    
    # Dockerfile.storefront (will be updated after storefront scaffolding)
    cat > "$PROJECT_ROOT/infra/docker/Dockerfile.storefront" <<'EOF'
# Next.js Storefront Dockerfile
# To be updated after Next.js storefront is scaffolded

FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY apps/storefront/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY apps/storefront .

# Build
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
EOF
    
    # docker-compose.dev.yml
    cat > "$PROJECT_ROOT/infra/compose/docker-compose.dev.yml" <<'EOF'
version: '3.8'

services:
  postgres-dev:
    image: postgres:15-alpine
    container_name: farscape-postgres-dev
    environment:
      POSTGRES_USER: medusa_dev
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: medusa_dev
    ports:
      - "5433:5432"
    volumes:
      - postgres-dev-data:/var/lib/postgresql/data
    networks:
      - farscape-dev

  redis-dev:
    image: redis:7-alpine
    container_name: farscape-redis-dev
    ports:
      - "6380:6379"
    networks:
      - farscape-dev

  minio-dev:
    image: minio/minio:latest
    container_name: farscape-minio-dev
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: dev_access_key_12345
      MINIO_ROOT_PASSWORD: dev_secret_key_67890
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio-dev-data:/data
    networks:
      - farscape-dev

networks:
  farscape-dev:
    driver: bridge

volumes:
  postgres-dev-data:
  minio-dev-data:
EOF
    
    # docker-compose.prod.yml
    cat > "$PROJECT_ROOT/infra/compose/docker-compose.prod.yml" <<'EOF'
version: '3.8'

services:
  postgres-prod:
    image: postgres:15-alpine
    container_name: farscape-postgres-prod
    environment:
      POSTGRES_USER: medusa_prod
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: medusa_prod
    volumes:
      - postgres-prod-data:/var/lib/postgresql/data
    restart: unless-stopped
    networks:
      - farscape-prod

  redis-prod:
    image: redis:7-alpine
    container_name: farscape-redis-prod
    restart: unless-stopped
    networks:
      - farscape-prod

  minio-prod:
    image: minio/minio:latest
    container_name: farscape-minio-prod
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ACCESS_KEY}
      MINIO_ROOT_PASSWORD: ${MINIO_SECRET_KEY}
    volumes:
      - minio-prod-data:/data
    restart: unless-stopped
    networks:
      - farscape-prod

networks:
  farscape-prod:
    driver: bridge

volumes:
  postgres-prod-data:
  minio-prod-data:
EOF
    
    mark_step_complete "create_docker_files"
    success "Docker files created"
}

create_nginx_configs() {
    if is_step_complete "create_nginx_configs"; then
        info "Nginx configs already created, skipping..."
        return 0
    fi
    
    step "Creating Nginx configuration files..."
    
    # Main nginx.conf
    cat > "$PROJECT_ROOT/infra/nginx/nginx.conf" <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    gzip on;

    # Include site configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Store (storefront) config
    cat > "$PROJECT_ROOT/infra/nginx/sites/store.farscape.in.conf" <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name store.farscape.in;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name store.farscape.in;

    # SSL Configuration (update after SSL setup)
    ssl_certificate /etc/letsencrypt/live/farscape.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/farscape.in/privkey.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to Next.js storefront
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    
    # Admin config
    cat > "$PROJECT_ROOT/infra/nginx/sites/admin.farscape.in.conf" <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name admin.farscape.in;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name admin.farscape.in;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/farscape.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/farscape.in/privkey.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to Medusa admin
    location / {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    
    # API config
    cat > "$PROJECT_ROOT/infra/nginx/sites/api.farscape.in.conf" <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name api.farscape.in;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.farscape.in;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/farscape.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/farscape.in/privkey.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to Medusa API
    location / {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    
    mark_step_complete "create_nginx_configs"
    success "Nginx configuration files created"
}

create_gitignore() {
    if is_step_complete "create_gitignore"; then
        info "Root .gitignore already created, skipping..."
        return 0
    fi
    
    step "Creating root .gitignore..."
    
    cat > "$PROJECT_ROOT/.gitignore" <<'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Production
/build
/dist
/.next
/out

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.env.production
env/.env.production

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*

# OS
.DS_Store
Thumbs.db

# IDEs
.idea/
.vscode/
*.swp
*.swo
*~

# Testing
coverage/
.nyc_output/

# Misc
*.pem
.medusa/

# Backups
*.backup
*.bak
EOF
    
    mark_step_complete "create_gitignore"
    success "Root .gitignore created"
}

create_readme() {
    if is_step_complete "create_readme"; then
        info "README already created, skipping..."
        return 0
    fi
    
    step "Creating root README.md..."
    
    cat > "$PROJECT_ROOT/README.md" <<'EOF'
# Farscape B2B Ecommerce Platform

A lean, production-ready B2B ecommerce platform built with Medusa 2.x and Next.js 15.

## 🚀 Project Status

### ✅ Completed
- Infrastructure setup (Docker, Node.js, Nginx)
- Monorepo structure created
- Environment configurations
- Docker Compose files (dev + prod)
- Nginx reverse proxy configs

### ⏳ To Be Done
- Scaffold Next.js 15 storefront
- Scaffold Medusa 2.x backend
- Implement custom B2B modules (credit, supplier, pricing, negotiation)
- Set up CI/CD pipeline

## 📁 Project Structure

```
farscape/
├── apps/                    # Applications (to be scaffolded)
│   ├── storefront/         # Next.js 15 (⏳ pending)
│   ├── medusa-backend/     # Medusa 2.x (⏳ pending)
│   └── medusa-worker/      # Background jobs (⏳ pending)
├── infra/                   # Infrastructure configs
│   ├── docker/             # Dockerfiles
│   ├── compose/            # Docker Compose files
│   ├── nginx/              # Nginx configs
│   └── setup/              # Setup scripts
├── scripts/                 # Automation scripts
│   ├── dev/                # Development
│   ├── prod/               # Production
│   └── shared/             # Shared utilities
├── env/                     # Environment configs
├── services/                # Service configs (MinIO, Postgres)
└── docs/                    # Documentation
```

## 🏗️ Architecture

- **Backend**: Medusa 2.x with custom B2B modules
- **Storefront**: Next.js 15 with App Router
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Storage**: MinIO (S3-compatible)
- **Payments**: Razorpay
- **Reverse Proxy**: Nginx with SSL

## 🎯 Custom B2B Features (Planned)

- Credit-based checkout
- Dropship/supplier management
- Volume-based pricing tiers
- Price negotiation workflow

## 🛠️ Next Steps

1. **Scaffold Storefront:**
   ```bash
   cd /root/farscape/apps
   npx create-next-app@latest storefront --typescript --tailwind --app
   ```

2. **Scaffold Medusa Backend:**
   ```bash
   cd /root/farscape/apps
   npx create-medusa-app@latest medusa-backend
   ```

3. **Initialize Git Repository:**
   ```bash
   bash /root/farscape/infra/setup/03-init-git-repo.sh
   ```

## 📚 Documentation

- [Project Context](docs/PROJECT_CONTEXT.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Backup Strategy](docs/BACKUP_STRATEGY.md)

## 📝 License

UNLICENSED - Proprietary Software

---

**Author:** Gaurav <gaurav@farscape.io>  
**Organization:** Farscape-official  
**Created:** February 2026
EOF
    
    mark_step_complete "create_readme"
    success "README.md created"
}

create_script_placeholders() {
    if is_step_complete "create_script_placeholders"; then
        info "Script placeholders already created, skipping..."
        return 0
    fi
    
    step "Creating script placeholders..."
    
    # Dev scripts
    local dev_scripts=(
        "setup-dev.sh"
        "start-dev.sh"
        "stop-dev.sh"
        "restart-dev.sh"
        "logs-dev.sh"
        "test-dev.sh"
    )
    
    for script in "${dev_scripts[@]}"; do
        cat > "$PROJECT_ROOT/scripts/dev/$script" <<EOF
#!/bin/bash
# ${script} - To be implemented
echo "Script: ${script}"
echo "Status: Not yet implemented"
echo ""
echo "This script will be created after storefront and backend are scaffolded"
EOF
        chmod +x "$PROJECT_ROOT/scripts/dev/$script"
    done
    
    # Prod scripts
    local prod_scripts=(
        "setup-prod.sh"
        "deploy-prod.sh"
        "start-prod.sh"
        "stop-prod.sh"
        "restart-prod.sh"
        "logs-prod.sh"
        "rollback-prod.sh"
    )
    
    for script in "${prod_scripts[@]}"; do
        cat > "$PROJECT_ROOT/scripts/prod/$script" <<EOF
#!/bin/bash
# ${script} - To be implemented
echo "Script: ${script}"
echo "Status: Not yet implemented"
echo ""
echo "This script will be created after storefront and backend are scaffolded"
EOF
        chmod +x "$PROJECT_ROOT/scripts/prod/$script"
    done
    
    # Shared scripts
    local shared_scripts=(
        "health-check.sh"
        "backup-db.sh"
        "backup-minio.sh"
        "restore-db.sh"
        "cleanup-old-images.sh"
    )
    
    for script in "${shared_scripts[@]}"; do
        cat > "$PROJECT_ROOT/scripts/shared/$script" <<EOF
#!/bin/bash
# ${script} - To be implemented
echo "Script: ${script}"
echo "Status: Not yet implemented"
echo ""
echo "This script will be created in a later phase"
EOF
        chmod +x "$PROJECT_ROOT/scripts/shared/$script"
    done
    
    mark_step_complete "create_script_placeholders"
    success "Script placeholders created"
}

set_permissions() {
    if is_step_complete "set_permissions"; then
        info "Permissions already set, skipping..."
        return 0
    fi
    
    step "Setting proper permissions..."
    
    # Set ownership
    execute "chown -R $OWNER:$GROUP $PROJECT_ROOT"
    
    # Set directory permissions (755)
    execute "find $PROJECT_ROOT -type d -exec chmod 755 {} +"
    
    # Set file permissions (644)
    execute "find $PROJECT_ROOT -type f -exec chmod 644 {} +"
    
    # Make scripts executable (755)
    execute "find $PROJECT_ROOT/scripts -type f -name '*.sh' -exec chmod 755 {} +"
    
    # Protect environment files (600)
    execute "chmod 600 $PROJECT_ROOT/env/.env.* 2>/dev/null || true"
    
    mark_step_complete "set_permissions"
    success "Permissions set"
}

################################################################################
# SUMMARY FUNCTION
################################################################################

print_summary() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Farscape Monorepo Creation - Summary"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "✅ Root structure created at: $PROJECT_ROOT"
    echo "✅ Infrastructure configured: Docker, Compose, Nginx"
    echo "✅ Scripts placeholders created: dev, prod, shared"
    echo "✅ Environment templates created"
    echo "✅ Permissions set"
    echo ""
    echo "⏳ Apps (to be scaffolded separately):"
    echo "   - storefront/ (Next.js 15)"
    echo "   - medusa-backend/ (Medusa 2.x)"
    echo "   - medusa-worker/ (Background jobs)"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Directory Structure"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    if command -v tree >/dev/null 2>&1; then
        tree -L 3 -d "$PROJECT_ROOT" 2>/dev/null || ls -la "$PROJECT_ROOT"
    else
        find "$PROJECT_ROOT" -maxdepth 3 -type d | sort
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Next Steps"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "1. Review the structure:"
    echo "   cd $PROJECT_ROOT"
    echo "   cat README.md"
    echo ""
    echo "2. Take Hetzner snapshot:"
    echo "   Name: farscape-02-monorepo-created"
    echo "   Description: Infrastructure and folder structure created"
    echo ""
    echo "3. Initialize Git repository:"
    echo "   bash 03-init-git-repo.sh"
    echo ""
    echo "4. Scaffold applications (after Git init):"
    echo "   See apps/storefront/README.md"
    echo "   See apps/medusa-backend/README.md"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo ""
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    clear 2>/dev/null || true

    echo "════════════════════════════════════════════════════════════════"
    echo "  Farscape B2B Platform - Create Monorepo Structure"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "This script will create:"
    echo "  • Complete folder structure"
    echo "  • Docker configurations (dev + prod)"
    echo "  • Nginx reverse proxy configs"
    echo "  • Environment file templates"
    echo "  • Automation script placeholders"
    echo ""
    echo "⚠️  Apps will NOT be scaffolded (done separately):"
    echo "  • storefront/ (Next.js 15)"
    echo "  • medusa-backend/ (Medusa 2.x)"
    echo "  • medusa-worker/ (Background jobs)"
    echo ""
    echo "Location: $PROJECT_ROOT"
    echo "Owner: $OWNER"
    echo "Package Manager: $PACKAGE_MANAGER"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        warn "DRY RUN MODE - No changes will be made"
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    # Pre-flight checks
    check_root
    validate_prerequisites
    
    # Create backup
    create_backup
    
    info "Starting monorepo creation..."
    
    # Execute creation steps
    create_root_structure
    create_apps_structure
    create_infra_structure
    create_scripts_structure
    create_services_structure
    
    create_root_package_json
    create_app_placeholders
    create_env_files
    create_docker_files
    create_nginx_configs
    create_gitignore
    create_readme
    create_script_placeholders
    
    set_permissions
    
    # Print summary
    print_summary
    
    success "Monorepo structure creation completed successfully!"
    info "Log file: ${LOG_FILE}"
    info "State file: ${STATE_FILE}"
    
    exit 0
}

# Run main function
main "$@"
