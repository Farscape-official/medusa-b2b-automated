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
