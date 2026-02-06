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

