## Environment & Setup Questions

### 1. Development Environment

**Q: What OS are you using locally?**  
**A:** Windows

**Q: Do you have Docker installed locally?**  
**A:** No, we have to install everything on the server

**Q: Current Node.js version?**  
**A:** Unknown / Not installed locally (will be installed on server)

**Q: Do you use npm, yarn, or pnpm?**  
**A:** **npm** (possibly pnpm for speed, but most probably npm)

---

### 2. Server/Production Environment

**Q: Hetzner VMs already provisioned, or starting fresh?**  
**A:** Fresh server

**Q: Ubuntu version on production server?**  
**A:** Ubuntu 24.04

**Q: How many VMs?**  
**A:** **Single VM** - Different environments managed via Docker Compose files and .env files

**Q: SSH access method?**  
**A:** Yes, key-based passwordless SSH

**SSH Users:** `root` and `user`  
**SSH Key Location (Windows):** `C:\Users\gaura\.ssh`

---

### 3. Current Project State

**Q: Is the monorepo structure already created?**  
**A:** No, nothing is built. Starting from scratch.

**Q: Do you have Medusa backend and Next.js storefront scaffolded?**  
**A:** Starting from scratch

**Q: Are the custom modules stubbed out?**  
**A:** No, starting from scratch

**Current Status:** VSCode connected to server using Remote SSH extension. Server is fresh Ubuntu 24.04.

---

### 4. Git & CI/CD

**Q: GitHub repository already created?**  
**A:** No, will be created using script file later

**Git Configuration:**
- **Username:** `gaurav-farscape`
- **Email:** `gaurav@farscape.io`
- **GitHub Profile:** https://github.com/gaurav-farscape
- **Organization:** `Farscape-official`
- **Organization URL:** https://github.com/Farscape-official
- **Repository Name:** `farscape` (to be created under organization)

---

### 5. Secrets & Configuration

**Q: Do you have .env templates ready?**  
**A:** No, but will follow architecture plan naming: `.env.dev` and `.env.production`

**Q: Razorpay credentials available?**  
**A:** Not specified yet

**Q: MinIO access keys defined?**  
**A:** Will be generated during setup

---

