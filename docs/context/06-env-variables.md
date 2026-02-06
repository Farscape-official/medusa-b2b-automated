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

