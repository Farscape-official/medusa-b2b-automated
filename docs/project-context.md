# Farscape B2B Ecommerce Platform - Project Context Document

**Last Updated:** February 4, 2026  
**Project Lead:** Gaurav  
**Organization:** Farscape-official

---

## Table of Contents

1. [Environment & Setup Questions](#environment--setup-questions)
2. [Architecture Decisions](#architecture-decisions)
3. [Git & Deployment Configuration](#git--deployment-configuration)
4. [Domain & Network Configuration](#domain--network-configuration)
5. [Script Architecture](#script-architecture)
6. [Environment Variables Structure](#environment-variables-structure)
7. [Port Mapping Strategy](#port-mapping-strategy)
8. [Initial Setup Workflow](#initial-setup-workflow)
9. [Pending Decisions](#pending-decisions)

---

## Environment & Setup Questions

### 1. Development Environment

**Q: What OS are you using locally?**  
**A:** Windows

**Q: Do you have Docker installed locally?**  
**A:** No, we have to install everything on the server

**Q: Current Node.js version?**  
**A:** Unknown / Not installed locally (will be installed on server)

**Q: Do you use npm, yarn, or pnpm?**  
**A:** **npm** (possibly pnpm for speed, but most probably npm)

---

### 2. Server/Production Environment

**Q: Hetzner VMs already provisioned, or starting fresh?**  
**A:** Fresh server

**Q: Ubuntu version on production server?**  
**A:** Ubuntu 24.04

**Q: How many VMs?**  
**A:** **Single VM** - Different environments managed via Docker Compose files and .env files

**Q: SSH access method?**  
**A:** Yes, key-based passwordless SSH

**SSH Users:** `root` and `user`  
**SSH Key Location (Windows):** `C:\Users\gaura\.ssh`

---

### 3. Current Project State

**Q: Is the monorepo structure already created?**  
**A:** No, nothing is built. Starting from scratch.

**Q: Do you have Medusa backend and Next.js storefront scaffolded?**  
**A:** Starting from scratch

**Q: Are the custom modules stubbed out?**  
**A:** No, starting from scratch

**Current Status:** VSCode connected to server using Remote SSH extension. Server is fresh Ubuntu 24.04.

---

### 4. Git & CI/CD

**Q: GitHub repository already created?**  
**A:** No, will be created using script file later

**Git Configuration:**
- **Username:** `gaurav-farscape`
- **Email:** `gaurav@farscape.io`
- **GitHub Profile:** https://github.com/gaurav-farscape
- **Organization:** `Farscape-official`
- **Organization URL:** https://github.com/Farscape-official
- **Repository Name:** `farscape` (to be created under organization)

---

### 5. Secrets & Configuration

**Q: Do you have .env templates ready?**  
**A:** No, but will follow architecture plan naming: `.env.dev` and `.env.production`

**Q: Razorpay credentials available?**  
**A:** Not specified yet

**Q: MinIO access keys defined?**  
**A:** Will be generated during setup

---

## Architecture Decisions

### Single Server, Multi-Environment Strategy

✅ **Confirmed Approach:**
- **One Hetzner VM** hosts both development and production environments
- **Environment separation** via:
  - `docker-compose.dev.yml` + `.env.dev` → Development environment
  - `docker-compose.prod.yml` + `.env.production` → Production environment
- **No separate dev/staging/prod servers** (single VM, multiple Docker environments)

### Why This Approach?

1. **Cost Efficiency:** Single server keeps hosting costs within ₹2L/year budget
2. **Operational Simplicity:** Easier to manage for lean team
3. **Environment Isolation:** Docker provides sufficient isolation between dev/prod
4. **Scalability Path:** Can split to multiple VMs later if traffic grows beyond 20 orders/day

---

## Domain & Network Configuration

### Production Domains

All domains point to Medusa services:

| Domain | Purpose | Service |
|--------|---------|---------|
| `store.farscape.in` | Customer-facing storefront | Next.js Storefront |
| `admin.farscape.in` | Admin dashboard | Medusa Admin UI |
| `api.farscape.in` | Backend API | Medusa Backend API |

**Note:** Medusa serves both admin UI and API from the same process on port 9000.

### Domain Routing (Production via Nginx)

```
store.farscape.in   → Next.js Storefront (internal port 3000)
admin.farscape.in   → Medusa Admin UI (internal port 9000/admin)
api.farscape.in     → Medusa Backend API (internal port 9000)
```

### Development Access (via IP or localhost)

```
Dev Storefront:  http://<server-ip>:3001
Dev Admin:       http://<server-ip>:9001/admin
Dev API:         http://<server-ip>:9001
```

---

## Script Architecture

### Phase 1: Initial Server Setup

```
infra/setup/
├── 01-system-setup.sh       # Install Docker, Node.js, npm, Git, UFW, fail2ban
├── 02-create-monorepo.sh    # Scaffold complete folder structure per architecture
├── 03-init-git-repo.sh      # Initialize Git, create .gitignore, connect to GitHub
└── 04-create-github-repo.sh # Create repo in Farscape-official organization
```

**What each script does:**

**01-system-setup.sh:**
- Updates Ubuntu 24.04 packages
- Installs Docker + Docker Compose
- Installs Node.js 20 LTS + npm
- Configures UFW firewall (ports 22, 80, 443 only)
- Sets up fail2ban for SSH protection
- Configures timezone and security hardening

**02-create-monorepo.sh:**
- Creates complete folder structure from architecture doc
- Scaffolds Medusa backend with custom modules (credit, supplier, pricing, negotiation)
- Scaffolds Next.js 15 storefront
- Creates Docker configurations
- Sets up scripts directory structure

**03-init-git-repo.sh:**
- Initializes Git repository
- Creates .gitignore with proper exclusions
- Configures Git user (gaurav@farscape.io)
- Makes initial commit with project structure

**04-create-github-repo.sh:**
- Creates repository under Farscape-official organization
- Pushes initial commit to GitHub
- (Requires GitHub Personal Access Token)

---

### Phase 2: Environment-Specific Scripts

```
scripts/
├── dev/
│   ├── setup-dev.sh         # One-time: create .env.dev, init databases
│   ├── start-dev.sh         # docker-compose -f dev up
│   ├── stop-dev.sh          # docker-compose -f dev down
│   ├── restart-dev.sh       # stop + start
│   ├── logs-dev.sh          # tail logs for dev services
│   └── test-dev.sh          # Run all tests in dev environment
│
├── prod/
│   ├── setup-prod.sh        # One-time: create .env.production, SSL certs
│   ├── deploy-prod.sh       # Build images + up with zero-downtime
│   ├── start-prod.sh        # docker-compose -f prod up -d
│   ├── stop-prod.sh         # docker-compose -f prod down
│   ├── restart-prod.sh      # rolling restart
│   ├── logs-prod.sh         # tail logs for prod services
│   └── rollback-prod.sh     # Rollback to previous Docker image tags
│
└── shared/
    ├── health-check.sh      # Check all services (accepts dev/prod arg)
    ├── backup-db.sh         # PostgreSQL backup (accepts dev/prod arg)
    ├── backup-minio.sh      # MinIO volume backup (accepts dev/prod arg)
    ├── restore-db.sh        # Restore from backup
    └── cleanup-old-images.sh # Remove old Docker images
```

---

### Phase 3: Infrastructure Configuration

```
infra/
├── docker/
│   ├── Dockerfile.medusa    # Medusa backend + worker image
│   └── Dockerfile.storefront # Next.js storefront image
│
├── compose/
│   ├── docker-compose.dev.yml      # Dev environment services
│   └── docker-compose.prod.yml     # Production environment services
│
├── nginx/
│   ├── nginx.conf           # Main Nginx configuration
│   └── sites/
│       ├── store.farscape.in.conf   # Storefront reverse proxy
│       ├── admin.farscape.in.conf   # Admin reverse proxy
│       └── api.farscape.in.conf     # API reverse proxy
│
└── scripts/                  # Production automation (from architecture doc)
    ├── backup-db.sh         # Database backup automation
    ├── backup-minio.sh      # MinIO volume backup
    ├── deploy-prod.sh       # Automated deployment
    └── rollback.sh          # Quick rollback script
```

---

### Phase 4: Environment Files

```
env/
├── .env.dev                 # Dev environment (committed with dummy values)
├── .env.dev.example         # Template for developers
├── .env.production          # Production secrets (NEVER committed to Git)
└── .env.production.example  # Template with placeholders
```

---

### Phase 5: Application Structure (Monorepo)

```
farscape/
├── apps/
│   ├── storefront/                    # Next.js 15 App Router
│   │   ├── src/
│   │   ├── public/
│   │   ├── package.json
│   │   └── next.config.js
│   │
│   ├── medusa-backend/                # Core commerce engine
│   │   ├── src/
│   │   │   ├── modules/
│   │   │   │   ├── credit/           # Credit-based checkout
│   │   │   │   ├── supplier/         # Dropship/Supplier management
│   │   │   │   ├── pricing/          # Volume pricing tiers
│   │   │   │   └── negotiation/      # Price negotiation module
│   │   │   └── api/
│   │   │       └── routes/
│   │   │           └── hooks/
│   │   │               └── razorpay/  # Razorpay webhook listener
│   │   ├── medusa-config.js
│   │   └── package.json
│   │
│   └── medusa-worker/                 # Background worker tasks
│       ├── src/
│       └── package.json
│
├── infra/                             # All infrastructure code
├── scripts/                           # Automation scripts
├── env/                               # Environment configurations
├── services/
│   ├── minio/                         # MinIO configuration
│   └── postgres/
│       └── init.sql                   # Custom B2B schema extensions
│
├── docs/
│   ├── PROJECT_CONTEXT.md            # This file
│   ├── SETUP.md                      # Setup guide
│   ├── DEPLOYMENT.md                 # Deployment procedures
│   └── RUNBOOK.md                    # Operational runbook
│
├── package.json                       # Root package.json (workspaces)
├── .gitignore
└── README.md
```

---

## Environment Variables Structure

### .env.dev (Development Environment)

```bash
# ============================================
# NODE ENVIRONMENT
# ============================================
NODE_ENV=development

# ============================================
# MEDUSA BACKEND CONFIGURATION
# ============================================
MEDUSA_BACKEND_URL=http://localhost:9001
MEDUSA_ADMIN_URL=http://localhost:9001/admin
DATABASE_URL=postgresql://medusa_dev:dev_password@postgres-dev:5432/medusa_dev
REDIS_URL=redis://redis-dev:6379

# ============================================
# MINIO (S3-COMPATIBLE OBJECT STORAGE)
# ============================================
MINIO_ENDPOINT=http://minio-dev:9000
MINIO_ACCESS_KEY=dev_access_key_12345
MINIO_SECRET_KEY=dev_secret_key_67890
MINIO_BUCKET=farscape-dev
MINIO_USE_SSL=false

# ============================================
# RAZORPAY (TEST CREDENTIALS)
# ============================================
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=test_secret_xxxxxxxxxxxxxxxx
RAZORPAY_WEBHOOK_SECRET=test_webhook_secret

# ============================================
# NEXT.JS STOREFRONT
# ============================================
NEXT_PUBLIC_MEDUSA_BACKEND_URL=http://localhost:9001
NEXT_PUBLIC_BASE_URL=http://localhost:3001

# ============================================
# EMAIL (BREVO/SENDINBLUE OR SIMILAR)
# ============================================
EMAIL_FROM=dev@farscape.io
EMAIL_PROVIDER=brevo
EMAIL_API_KEY=dev_email_api_key_xxxxx

# ============================================
# SECURITY (Development - Weak for convenience)
# ============================================
JWT_SECRET=dev_jwt_secret_not_for_production
COOKIE_SECRET=dev_cookie_secret_not_for_production

# ============================================
# LOGGING
# ============================================
LOG_LEVEL=debug
```

---

### .env.production (Production Environment - NEVER COMMITTED)

```bash
# ============================================
# NODE ENVIRONMENT
# ============================================
NODE_ENV=production

# ============================================
# MEDUSA BACKEND CONFIGURATION
# ============================================
MEDUSA_BACKEND_URL=https://api.farscape.in
MEDUSA_ADMIN_URL=https://admin.farscape.in
DATABASE_URL=postgresql://medusa_prod:CHANGE_THIS_SECURE_PASSWORD@postgres-prod:5432/medusa_prod
REDIS_URL=redis://redis-prod:6379

# ============================================
# MINIO (S3-COMPATIBLE OBJECT STORAGE)
# ============================================
MINIO_ENDPOINT=https://minio.farscape.in
MINIO_ACCESS_KEY=PRODUCTION_ACCESS_KEY_CHANGE_THIS
MINIO_SECRET_KEY=PRODUCTION_SECRET_KEY_CHANGE_THIS
MINIO_BUCKET=farscape-prod
MINIO_USE_SSL=true

# ============================================
# RAZORPAY (LIVE CREDENTIALS)
# ============================================
RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=live_secret_xxxxxxxxxxxxxxxx
RAZORPAY_WEBHOOK_SECRET=live_webhook_secret_xxxxxxxx

# ============================================
# NEXT.JS STOREFRONT
# ============================================
NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://api.farscape.in
NEXT_PUBLIC_BASE_URL=https://store.farscape.in

# ============================================
# EMAIL (PRODUCTION)
# ============================================
EMAIL_FROM=noreply@farscape.io
EMAIL_PROVIDER=brevo
EMAIL_API_KEY=PRODUCTION_EMAIL_API_KEY_CHANGE_THIS

# ============================================
# SECURITY (Production - MUST BE STRONG)
# ============================================
# Generate using: openssl rand -base64 64
JWT_SECRET=GENERATE_RANDOM_64_CHAR_STRING_HERE
COOKIE_SECRET=GENERATE_RANDOM_64_CHAR_STRING_HERE

# ============================================
# LOGGING
# ============================================
LOG_LEVEL=info

# ============================================
# SSL/TLS (Managed by Certbot/Let's Encrypt)
# ============================================
SSL_CERT_PATH=/etc/letsencrypt/live/farscape.in/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/farscape.in/privkey.pem
```

---

## Port Mapping Strategy

### Development Environment (Docker Internal + Exposed)

| Service | Container Name | Internal Port | Exposed Port | Access URL |
|---------|---------------|---------------|--------------|------------|
| PostgreSQL (dev) | postgres-dev | 5432 | 5433 | localhost:5433 |
| Redis (dev) | redis-dev | 6379 | 6380 | localhost:6380 |
| MinIO (dev) | minio-dev | 9000 | 9001 | localhost:9001 |
| Medusa Backend (dev) | medusa-backend-dev | 9000 | 9001 | localhost:9001 |
| Medusa Worker (dev) | medusa-worker-dev | - | - | (background) |
| Storefront (dev) | storefront-dev | 3000 | 3001 | localhost:3001 |

**Why exposed ports?**
- Allows direct access from host machine for debugging
- Database GUI tools can connect via localhost:5433
- MinIO web UI accessible at localhost:9001

---

### Production Environment (via Nginx Reverse Proxy)

| Domain | Service | Internal Port | SSL |
|--------|---------|---------------|-----|
| `store.farscape.in` | Storefront | 3000 | ✅ Yes |
| `admin.farscape.in` | Medusa Admin | 9000/admin | ✅ Yes |
| `api.farscape.in` | Medusa API | 9000 | ✅ Yes |
| (Internal only) | PostgreSQL | 5432 | N/A |
| (Internal only) | Redis | 6379 | N/A |
| (Internal only) | MinIO | 9000 | N/A |

**Security:**
- No direct port exposure to internet
- All traffic goes through Nginx with SSL termination
- Only ports 22 (SSH), 80 (HTTP→HTTPS redirect), 443 (HTTPS) open via UFW

---

## Initial Setup Workflow

### Prerequisites

1. ✅ Fresh Ubuntu 24.04 server on Hetzner
2. ✅ VSCode Remote SSH connected to server
3. ✅ SSH key-based authentication working
4. ⏳ Server IP address (to be provided)
5. ⏳ GitHub Personal Access Token (for repo creation)

---

### Step-by-Step Setup Commands

#### **Step 1: Connect to Server**

```bash
# From Windows, using VSCode Remote SSH
# (Already connected per current setup)

# Or via terminal:
ssh user@<server-ip>
```

---

#### **Step 2: Download Initial Setup Script**

Since the repository doesn't exist yet, we'll create a bootstrap script first:

```bash
# On the server
cd /home/user
mkdir farscape-setup
cd farscape-setup

# Download bootstrap script (will be provided separately)
# Or create manually from generated content
```

---

#### **Step 3: Run System Setup** (Root required)

```bash
sudo bash 01-system-setup.sh
```

**This script will:**
- ✅ Update Ubuntu packages
- ✅ Install Docker + Docker Compose
- ✅ Install Node.js 20 LTS + npm
- ✅ Install Git + build-essential
- ✅ Configure UFW firewall (SSH, HTTP, HTTPS only)
- ✅ Install fail2ban for SSH protection
- ✅ Set timezone to Asia/Kolkata (or as specified)
- ✅ Create `/var/log/farscape/` for centralized logging

**Expected duration:** 5-10 minutes

---

#### **Step 4: Create Monorepo Structure**

```bash
bash 02-create-monorepo.sh
```

**This script will:**
- ✅ Create complete folder structure per architecture
- ✅ Scaffold Medusa backend with custom module stubs
- ✅ Scaffold Next.js 15 storefront
- ✅ Create Dockerfile templates
- ✅ Create docker-compose files (dev + prod)
- ✅ Create all automation scripts
- ✅ Create environment file templates

**Expected duration:** 2-3 minutes

---

#### **Step 5: Initialize Git Repository**

```bash
cd /home/user/farscape
bash infra/setup/03-init-git-repo.sh
```

**This script will:**
- ✅ Initialize Git repository
- ✅ Create .gitignore with proper exclusions
- ✅ Configure Git user: gaurav@farscape.io
- ✅ Make initial commit with message: "Initial project structure"

**Expected duration:** < 1 minute

---

#### **Step 6: Create GitHub Repository**

```bash
bash infra/setup/04-create-github-repo.sh
```

**This script will:**
- ⚠️ Prompt for GitHub Personal Access Token
- ✅ Create repository under Farscape-official organization
- ✅ Push initial commit to GitHub
- ✅ Set main branch as default

**Alternative (Manual):**
1. Go to https://github.com/organizations/Farscape-official/repositories/new
2. Create repository named `farscape`
3. Run: `git remote add origin https://github.com/Farscape-official/farscape.git`
4. Run: `git push -u origin main`

**Expected duration:** 1-2 minutes

---

#### **Step 7: Setup Development Environment**

```bash
bash scripts/dev/setup-dev.sh
```

**This script will:**
- ✅ Create `.env.dev` from template
- ✅ Generate random secrets for JWT/Cookie
- ✅ Generate MinIO access keys
- ✅ Start Docker services (Postgres, Redis, MinIO)
- ✅ Wait for services to be healthy
- ✅ Run Medusa database migrations
- ✅ Seed initial data (admin user, sample products)
- ✅ Create MinIO buckets
- ✅ Display access credentials and URLs

**Expected duration:** 3-5 minutes

---

#### **Step 8: Start Development Services**

```bash
bash scripts/dev/start-dev.sh
```

**This script will:**
- ✅ Start all development services via docker-compose.dev.yml
- ✅ Show real-time logs
- ✅ Display access URLs

**Access the platform:**
- 🌐 Storefront: `http://<server-ip>:3001`
- 🔧 Admin: `http://<server-ip>:9001/admin`
- 📡 API: `http://<server-ip>:9001`
- 🗄️ MinIO: `http://<server-ip>:9001` (MinIO Console)

**Default admin credentials (created by setup-dev.sh):**
- Email: `admin@farscape.io`
- Password: `admin123` (change after first login)

---

#### **Step 9: Verify Installation**

```bash
bash scripts/shared/health-check.sh dev
```

**This script will:**
- ✅ Check PostgreSQL connection
- ✅ Check Redis connection
- ✅ Check MinIO connection
- ✅ Check Medusa API health
- ✅ Check Storefront accessibility
- ✅ Display service status report

---

#### **Step 10: Run Tests**

```bash
bash scripts/dev/test-dev.sh
```

**This script will:**
- ✅ Run unit tests for custom modules
- ✅ Run integration tests (API endpoints)
- ✅ Run E2E tests (checkout flow)
- ✅ Generate test coverage report

---

### Daily Development Workflow

```bash
# Start your day
bash scripts/dev/start-dev.sh

# View logs in real-time
bash scripts/dev/logs-dev.sh

# Make changes to code...
# (VSCode Remote SSH auto-syncs)

# Run tests
bash scripts/dev/test-dev.sh

# Restart services if needed
bash scripts/dev/restart-dev.sh

# End of day - stop services
bash scripts/dev/stop-dev.sh
```

---

## Pending Decisions

### Critical (Needed for script generation)

1. **Server IP Address**
   - Required for: SSH examples, Nginx configuration, documentation
   - Status: ⏳ Awaiting input

2. **Package Manager Confirmation**
   - Options: `npm` or `pnpm`
   - Recommendation: `npm` for compatibility, `pnpm` for speed
   - Status: ⏳ Awaiting final decision

3. **Development SSH User**
   - Options: `root` or `user`
   - Recommendation: Use `user` for daily work, `root` only for system setup
   - Status: ⏳ Awaiting decision

4. **GitHub Personal Access Token**
   - Required for: Automated repository creation (04-create-github-repo.sh)
   - Alternative: Manual repository creation steps
   - Status: ⏳ Optional (can provide manual steps)

---

### Optional (Can decide during setup)

5. **Razorpay Credentials**
   - Test credentials for development
   - Live credentials for production
   - Status: ⏳ Can be added later to .env files

6. **Email Provider**
   - Brevo (Sendinblue) recommended for cost
   - Alternative: SendGrid, Amazon SES, Mailgun
   - Status: ⏳ Can be configured later

7. **DNS Configuration**
   - Are domains already pointing to server IP?
   - Status: ⏳ Required before production deployment

8. **SSL Certificate Strategy**
   - Automated via Certbot/Let's Encrypt (recommended)
   - Manual certificate upload
   - Status: ⏳ Will be handled by setup-prod.sh

9. **Backup Retention**
   - Database: 7 or 14 days?
   - MinIO: 14 or 30 days?
   - Status: ⏳ Defaults set per architecture doc

10. **Monitoring & Alerting**
    - UptimeRobot for basic uptime checks
    - Additional monitoring later as needed
    - Status: ⏳ Optional for initial launch

---

## Next Steps

### To Generate All Scripts & Configurations

Please provide:

1. ✅ **Server IP Address**: `_______________`
2. ✅ **Package Manager**: `npm` or `pnpm`
3. ✅ **Dev SSH User**: `root` or `user`
4. ❓ **GitHub Personal Access Token** (or skip for manual repo creation)

### What You'll Receive

Once you provide the above information, I will generate:

1. ✅ **All 20+ production-ready bash scripts**
   - Complete error handling
   - Idempotency checks
   - Logging to `/var/log/farscape/`
   - Non-interactive execution
   - Secrets validation

2. ✅ **Complete Docker configurations**
   - `docker-compose.dev.yml`
   - `docker-compose.prod.yml`
   - Dockerfiles for Medusa and Storefront

3. ✅ **Nginx configurations**
   - Reverse proxy for all domains
   - SSL termination
   - Security headers

4. ✅ **Environment file templates**
   - `.env.dev` with safe defaults
   - `.env.production.example` with placeholders

5. ✅ **Complete documentation**
   - SETUP.md (step-by-step guide)
   - DEPLOYMENT.md (production deployment)
   - RUNBOOK.md (operational procedures)

### Estimated Timeline

- ⏱️ Script generation: Immediate (once info provided)
- ⏱️ System setup (01): 5-10 minutes
- ⏱️ Monorepo creation (02): 2-3 minutes
- ⏱️ Git initialization (03): < 1 minute
- ⏱️ Dev environment setup (07): 3-5 minutes
- ⏱️ **Total time to working dev environment: ~15-20 minutes**

---

## File Storage Location

**Save this document as:**
- Local: `C:\Users\gaura\Documents\farscape\PROJECT_CONTEXT.md`
- Server: `/home/user/farscape/docs/PROJECT_CONTEXT.md`
- Git: Committed to repository root initially, then moved to `docs/`

**Version Control:**
- This document should be committed to Git
- Update as project evolves
- Always keep in sync with actual configuration

---

## Contact & Support

**Project Lead:** Gaurav  
**Email:** gaurav@farscape.io  
**GitHub:** https://github.com/gaurav-farscape  
**Organization:** https://github.com/Farscape-official

---

**Document Version:** 1.0  
**Created:** February 4, 2026  
**Last Modified:** February 4, 2026

---

## Appendix: Quick Reference Commands

```bash
# One-liner: Fresh Ubuntu → Working Dev Environment
sudo bash infra/setup/01-system-setup.sh && \
bash infra/setup/02-create-monorepo.sh && \
bash infra/setup/03-init-git-repo.sh && \
bash scripts/dev/setup-dev.sh && \
bash scripts/dev/start-dev.sh

# Daily workflow
bash scripts/dev/start-dev.sh    # Start services
bash scripts/dev/logs-dev.sh     # View logs
bash scripts/dev/test-dev.sh     # Run tests
bash scripts/dev/stop-dev.sh     # Stop services

# Health checks
bash scripts/shared/health-check.sh dev   # Check dev environment
bash scripts/shared/health-check.sh prod  # Check prod environment

# Backups
bash scripts/shared/backup-db.sh dev      # Backup dev database
bash scripts/shared/backup-db.sh prod     # Backup prod database

# Production deployment
bash scripts/prod/setup-prod.sh           # One-time setup
bash scripts/prod/deploy-prod.sh          # Deploy to production
bash scripts/prod/rollback-prod.sh        # Rollback if needed
```

---

**End of Document**
