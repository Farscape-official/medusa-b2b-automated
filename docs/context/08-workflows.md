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

