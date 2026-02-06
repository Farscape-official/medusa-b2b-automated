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

