# InstituteOS — Version Acceptance Gates & Exit Criteria

**Document Version:** 1.0.0  
**Status:** Approved Quality Governance Standard  
**Governance Principle:** No Automatic Sign-Off. Explicit Multi-Disciplinary Audit Required for Every Version.  

---

## 1. Governance Rules for Version Transitions

To protect the architectural integrity and operational stability of InstituteOS, progression from Version \(N\) to Version \(N+1\) is governed by strict, measurable exit criteria:

1. **No Automatic Sign-Off:** Passing unit tests and green CI builds are necessary conditions, but **never sufficient** on their own. A formal audit review must be conducted by the Lead Architect, QA Lead, and Security Engineer.
2. **Zero Known Critical Defects:** A version cannot be signed off with open P0 (Critical) or P1 (High) security, financial, or isolation bugs.
3. **Audit Trail Artifact:** Every completed version requires an explicit, immutable sign-off document (`docs/audits/V{N}_AUDIT_REPORT.md`) containing verifiable test execution logs and benchmark results.

---

## 2. Version 1: Core Foundation Acceptance Gate

```
┌────────────────────────────────────────────────────────────────────────┐
│                        V1 ACCEPTANCE AUDIT GATE                        │
├────────────────────┬──────────────────────────────────────┬────────────┤
│ PILLAR             │ VERIFIABLE CRITERIA                  │ VERIFIED BY│
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 1. Tenant          │ 100% of tenant tables have enabled   │ Automated  │
│    Isolation (RLS) │ RLS; automated test suite passes 50+ │ CI pgTAP   │
│                    │ cross-tenant injection attack tests. │ Suite      │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 2. Authentication  │ Login, logout, session refresh, and  │ Playwright │
│    & IAM           │ password reset function; session     │ E2E        │
│                    │ revocation terminates active tokens. │ Tests      │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 3. Database &      │ All foundational tables created via  │ Supabase   │
│    Migrations      │ forward-only migrations; composite   │ Migration  │
│                    │ tenant indexes verified.             │ Linter     │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 4. Design System   │ Accessible Next.js shell with        │ Lighthouse │
│    & Shell UI      │ responsive sidebar; WCAG 2.2 AA      │ Axe Core   │
│                    │ score > 95%; i18n dictionary hooks.  │ Audit      │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 5. Audit Logging   │ System table captures authentication │ DB Trigger │
│    Foundation      │ and tenant mutations; UPDATE/DELETE  │ Test       │
│                    │ on audit logs throws SQL exceptions. │            │
└────────────────────┴──────────────────────────────────────┴────────────┘
```

---

## 3. Version 2: Daily Operations Acceptance Gate

```
┌────────────────────────────────────────────────────────────────────────┐
│                        V2 ACCEPTANCE AUDIT GATE                        │
├────────────────────┬──────────────────────────────────────┬────────────┤
│ PILLAR             │ VERIFIABLE CRITERIA                  │ VERIFIED BY│
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 1. Admissions &    │ Student admission workflow functions │ Playwright │
│    Lifecycle       │ from enquiry to enrollment; student  │ E2E        │
│                    │ roll numbers unique per institute.   │ Journey    │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 2. Attendance      │ Teacher can record daily and period- │ Performance│
│    Engine          │ wise attendance for 40 students in   │ Benchmark  │
│                    │ < 30 seconds; duplicate dates error. │ (< 1 sec)  │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 3. Fees & Receipt  │ Sequential receipt numbering with    │ SQL Audit  │
│    Generation      │ zero gaps; immutable PDF receipts    │ Script &   │
│                    │ render with institute branding.      │ Hash Check │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 4. Financial       │ Erroneous payments cannot be deleted;│ Negative DB│
│    Integrity       │ corrections generate formal credit   │ Mutation   │
│                    │ adjustment records with audit trail. │ Test       │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 5. Bulk CSV        │ Import utility successfully parses,  │ Synthetic  │
│    Import          │ validates, and imports 500+ student  │ CSV Batch  │
│                    │ rows, generating error report sheet. │ Runner     │
└────────────────────┴──────────────────────────────────────┴────────────┘
```

---

## 4. Version 3: Academics & Communications Acceptance Gate

```
┌────────────────────────────────────────────────────────────────────────┐
│                        V3 ACCEPTANCE AUDIT GATE                        │
├────────────────────┬──────────────────────────────────────┬────────────┤
│ PILLAR             │ VERIFIABLE CRITERIA                  │ VERIFIED BY│
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 1. Timetables &    │ Timetable builder detects faculty    │ Algorithmic│
│    Scheduling      │ and classroom collisions across all  │ Collision  │
│                    │ branches in the institute.           │ Unit Tests │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 2. Exams & Report  │ Marks entry enforces validation      │ Bulk PDF   │
│    Cards           │ ranges; batch PDF report cards       │ Benchmark  │
│                    │ render at < 2 seconds per card.      │ Runner     │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 3. Omnichannel     │ Student marked absent dispatches an  │ Webhook    │
│    Notifications   │ SMS/WhatsApp event through queue;    │ Delivery   │
│                    │ carrier delivery receipt logged.     │ Log Audit  │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 4. DLT Telecom     │ Indian SMS dispatches validate       │ DLT Policy │
│    Compliance      │ registered Principal Entity & Header │ Schema     │
│                    │ IDs prior to gateway transmission.   │ Linter     │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 5. Mobile API      │ REST endpoints (`/api/v1/...`)       │ OpenAPI    │
│    Readiness       │ documented in OpenAPI 3.1 with       │ Validator  │
│                    │ JWT authentication and rate limits.  │ & Postman  │
└────────────────────┴──────────────────────────────────────┴────────────┘
```

---

## 5. Version 4: Websites, SaaS Platform & Mobile Apps Acceptance Gate

```
┌────────────────────────────────────────────────────────────────────────┐
│                        V4 ACCEPTANCE AUDIT GATE                        │
├────────────────────┬──────────────────────────────────────┬────────────┤
│ PILLAR             │ VERIFIABLE CRITERIA                  │ VERIFIED BY│
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 1. Public CMS &    │ Institute can configure custom       │ DNS & SSL  │
│    Custom Domains  │ CNAME; Let's Encrypt SSL provisions; │ Automated  │
│                    │ public enquiry form captures leads.  │ Probe      │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 2. SaaS Billing &  │ Plan student quotas enforced;        │ Mock Stripe│
│    Entitlements    │ expired subscription triggers 15-day │ Webhook    │
│                    │ grace period then Read-Only mode.    │ Simulator  │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 3. Online Payment  │ Server-side webhook HMAC signature   │ Cryptograph│
│    Verification    │ verification marks fee cleared;      │ Signature  │
│                    │ client-reported status rejected.     │ Test       │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 4. Mobile Apps     │ React Native app runs on iOS/Android;│ Device Lab │
│    (iOS / Android) │ offline attendance syncs on reconnect│ & Network  │
│                    │ without conflict; payments blocked.  │ Kill Test  │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 5. Developer API   │ Third-party API keys query data with │ Scoped Key │
│    & Webhooks      │ rate limiting; signed webhooks fire. │ Test Suite │
└────────────────────┴──────────────────────────────────────┴────────────┘
```

---

## 6. Version 5: Production Hardening & Compliance Acceptance Gate

```
┌────────────────────────────────────────────────────────────────────────┐
│                        V5 ACCEPTANCE AUDIT GATE                        │
├────────────────────┬──────────────────────────────────────┬────────────┤
│ PILLAR             │ VERIFIABLE CRITERIA                  │ VERIFIED BY│
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 1. Double-Entry    │ 100% of journal entries strictly     │ Trigger &  │
│    General Ledger  │ balanced (sum debits = sum credits); │ General    │
│                    │ automated Trial Balance balances.    │ Ledger Run │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 2. Indian GST      │ Invoices generate compliant tax lines│ Chartered  │
│    Compliance      │ (CGST/SGST/IGST); HSN/SAC mapped;    │ Accountant │
│                    │ GST return summary exports properly. │ Review     │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 3. DPDP Act &      │ Student personal data export JSON    │ Privacy    │
│    Legal Holds     │ works; deletion anonymization works; │ Workflow   │
│                    │ legal hold blocks deletion triggers. │ Assertion  │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 4. Disaster        │ Simulated production recovery drill  │ Full Drill │
│    Recovery Drill  │ restores database snapshot to PITR   │ Log & Data │
│                    │ with RTO < 4 hours and RPO < 1 hour. │ Diff Check │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 5. High-Scale Load │ System sustains 10,000 simulated     │ k6 /       │
│    Hardening       │ concurrent users with p95 < 500ms    │ Artillery  │
│                    │ and 0% cross-tenant data leakage.    │ Load Test  │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 6. Pen-Testing &   │ Independent penetration test reports │ Security   │
│    Security Signoff│ zero critical/high vulnerabilities;  │ Pentest    │
│                    │ executive sign-off for live launch.  │ Report     │
└────────────────────┴──────────────────────────────────────┴────────────┘
```
