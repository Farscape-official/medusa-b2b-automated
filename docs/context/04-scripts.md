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

