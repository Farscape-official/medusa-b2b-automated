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
