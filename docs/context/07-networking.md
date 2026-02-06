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

