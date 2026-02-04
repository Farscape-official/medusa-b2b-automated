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
