# Project: Monorepo Automation & System Setup
# Role: Senior DevOps & Full-Stack Engineer

## 🏗 Project Architecture & Boundaries
- **Root Directory:** `/root/automation_scripts` (Management & Orchestration)
- **Monorepo Root:** `/opt/project-root` (Application Source)
- **Boundary:** Scripts must not modify `/etc/` system configs unless explicitly declared.
- **Structure:** Modular bash scripts; Workspace-based isolation for apps.

## 🔄 Versioning & Release Strategy
- **Format:** Semantic Versioning (MAJOR.MINOR.PATCH) required in script headers.
- **Changelog:** Mandatory `CHANGELOG.md` update for every logic change.
- **Tagging:** Git tags must match script versioning for traceability.

## 🛡 Rollback & Recovery Policy
- **Pre-flight:** Scripts must verify system state/dependencies before execution.
- **Backups:** Critical files (e.g., `/etc/nginx/conf.d`) must be backed up to `/tmp/backup_[timestamp]` before modification.
- **Failure State:** On error, scripts must attempt an automated rollback to the last known stable state or provide a `--rollback` flag.

## 📜 Development & Logic Rules
- **Error Handling:** Mandatory `try-catch` (or `set -e`). Log to `stderr` and rethrow.
- **Logging:** `[TIMESTAMP] [LEVEL] Message`. Use `logger` for system events.
- **Security:** No hardcoded secrets. Use env vars. Permissions: 755 (scripts), 644 (configs).
- **Idempotency:** All scripts must be safe to run multiple times.

## 🛠 Dependency & Testing Standards
- **Approval:** Active maintenance, <10% size impact, MIT/Apache license.
- **Testing:** 100% coverage for core utilities. Pass `shellcheck`.
- **Merge Req:** Must pass linting, unit tests, and include updated documentation.

## 💸 Token-Saving & Efficiency Protocols
- **Rule-Violation Policy:** If rules are breached, stop and regenerate immediately.
- **Conciseness:** Zero filler. No conversational intros/outros.
- **Diffs only:** Provide specific line updates for existing files.

## 🔍 Pre-Response Self-Validation (Mandatory)
1. Is the versioning updated? 
2. Is there a recovery path for this change?
3. Are all errors logged and rethrown?
4. Minimum tokens used?

## 📋 Response Format
1. **Summary:** 1-sentence technical gist.
2. **Code:** The solution.
3. **Validation:** "Validated against claude.md rules."