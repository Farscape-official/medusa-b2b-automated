# Farscape B2B Platform

# Automation Script Inventory & Checklist

##### Project: Farscape B2B Ecommerce Platform

##### Author: Gaurav (gaurav@farscape.io)

##### Organization: Farscape-official

##### Generated: February 05, 2026 at 08:

##### Total Scripts: 26 (Critical + High Priority)

## n PHASE 1: CRITICAL SCRIPTS (18)

#### Must have - required to get platform running

## A. Initial Setup & Infrastructure (4 scripts)

##### # Script Purpose Status

```
1 01-system-setup.sh System dependencies, Docker, Node.js n DONE
2 02-create-monorepo.sh Complete folder structure n DONE
3 03-init-git-repo.sh Git initialization n DONE
4 04-create-github-repo.sh Push to GitHub n DONE
```
## B. App Scaffolding (3 scripts)

##### # Script Purpose Status

```
5 05-integrate-b2b-starter.sh B2B starter clone & mapping n DONE
6 06-configure-apps.sh App config, envs, module paths n DONE
7 07-install-dependencies.sh Monorepo workspace npm install n DONE
```
## C. Development Environment (3 scripts)

##### # Script Purpose Status

```
8 scripts/dev/setup-dev.sh One-time dev environment setup n NEXT
9 scripts/dev/start-dev.sh Start dev services n Pending
10 scripts/dev/stop-dev.sh Stop dev services n Pending
```

### D. Production Deployment (4 scripts)

##### # Script Purpose Status

```
11 scripts/prod/setup-prod.sh One-time prod setup (SSL, Nginx) n Pending
12 scripts/prod/deploy-prod.sh Deploy to production n Pending
13 scripts/prod/start-prod.sh Start production services n Pending
14 scripts/prod/rollback-prod.sh Emergency rollback n Pending
```
### E. Backup & Recovery (3 scripts)

#### Per Backup & Recovery Strategy: PostgreSQL every 2hrs, MinIO daily

##### # Script Frequency Status

```
15 scripts/shared/backup-db.sh Every 2 hours (cron) n Pending
16 scripts/shared/backup-minio.sh Daily (cron) n Pending
17 scripts/shared/restore-db.sh On-demand (emergency) n Pending
```
### F. Essential Monitoring (1 script)

##### # Script Purpose Status

```
18 scripts/shared/health-check.sh Verify all services running n Pending
```

## n PHASE 2: HIGH PRIORITY SCRIPTS (8)

#### Add within 2 weeks after launch

##### # Script Purpose Status

```
19 scripts/dev/logs-dev.sh View dev logs easily n Later
20 scripts/prod/logs-prod.sh View production logs n Later
21 scripts/dev/restart-dev.sh Quick dev restart n Later
22 scripts/prod/stop-prod.sh Stop production safely n Later
23 scripts/shared/cleanup-old-images.sh Free disk space n Later
24 scripts/shared/prune-old-backups.sh Auto-delete old backups n Later
25 scripts/shared/migrate-db.sh Run Medusa migrations n Later
26 scripts/prod/ssl-renew.sh Renew SSL certificates n Later
```
## n EXECUTION SEQUENCE

##### Phase Steps Actions

```
Setup
(1-4)
Scripts 1-4 System setup → Monorepo → Git → GitHub
Take snapshot after each
Scaffold
(5-7)
Scripts 5-7 Scaffold apps → Install dependencies
Take snapshot after step 7
Dev Env
(8-10)
Scripts 8-10 Setup dev → Start/Stop scripts
Take final snapshot after step 8
Backups
(15-17)
Scripts 15-17 Setup cron jobs for automated backups
```
```
Production
(11-14)
Scripts 11-14 Setup prod → Deploy → Start → Rollback ready
```
```
Monitor
(18)
Script 18 Health checks for all services
```
## n SNAPSHOT STRATEGY (Max 5)

##### # Snapshot Name Taken After Purpose

```
1 farscape-01-system-setup Script #1 Clean system with dependencies
```

```
2 farscape-02-monorepo-created Script #2 Folder structure ready
3 farscape-03-git-initialized Script #4 Git repo with initial commit
4 farscape-04-apps-scaffolded Script #7 Apps created, deps installed
5 farscape-05-dev-ready Script #8 Dev environment configured
```
##### Note: When creating snapshot #6, delete snapshot #1 and rotate.

## n SUMMARY

#### Priority Scripts Timeline Status

##### n Critical 18 Build now (1-2 weeks) 7 of 18 done

##### n High 8 After launch (2-4 weeks) Not started

##### Total Active 26 Focus on these only 7 of 26 done


