# InstituteOS — Version Acceptance Gates & Exit Criteria

**Document Version:** 1.1.0 (Remediated Baseline)  
**Status:** Approved Quality Governance Standard  
**Governance Principle:** No Automatic Sign-Off. Explicit Multi-Disciplinary Audit Required for Every Version.  

---

## 1. Governance Rules for Version Transitions

Progression from Version \(N\) to Version \(N+1\) is governed by strict, measurable exit criteria:

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
│    Isolation (RLS) │ RLS with FORCE RLS; branch managers  │ CI pgTAP   │
│                    │ cannot view staff assignments outside│ Suite      │
│                    │ assigned branches. Zero cross-tenant.│            │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 2. Attendance-Rule │ Full 4-tier inheritance engine:      │ PostgreSQL │
│    Inheritance     │ Inst -> Branch -> Course -> Class.   │ Test Suite │
│    Engine          │ Precedence: Class > Course > Branch  │ & Function │
│                    │ > Institute. Fallbacks, validation,  │ Tests      │
│                    │ audit history verified.              │            │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 3. Authentication  │ Login, logout, session refresh, and  │ Playwright │
│    & IAM           │ password reset function; session     │ E2E        │
│                    │ revocation terminates active tokens. │ Tests      │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 4. Database &      │ All foundational tables created via  │ Supabase   │
│    Migrations      │ forward-only migrations; composite   │ Migration  │
│                    │ tenant indexes verified.             │ Linter     │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 5. Audit Logging   │ Audit logs protected by row UPDATE/  │ DB Trigger │
│    Hardening       │ DELETE trigger and statement TRUNCATE│ Test       │
│                    │ trigger set to ENABLE ALWAYS.        │            │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 6. Design System   │ Accessible Next.js shell with        │ Lighthouse │
│    & Shell UI      │ responsive sidebar; WCAG 2.2 AA      │ Axe Core   │
│                    │ score > 95%; i18n dictionary hooks.  │ Audit      │
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
│ 2. Attendance      │ Attendance recording evaluated       │ Performance│
│    Engine          │ against V1 attendance-rule hierarchy;│ Benchmark  │
│                    │ 40 students marked in < 30 seconds.  │ (< 1 sec)  │
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

## 4. Version 3: Academics & Dual-Mode Communications Acceptance Gate

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
│ 3. Dual-Mode SMS   │ Both BYO credentials and platform-   │ Webhook &  │
│    & Notifications │ managed credit pool function. Credit │ Ledger     │
│                    │ ledger deductions verified.          │ Audit      │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 4. DLT Telecom     │ Indian SMS dispatches validate       │ DLT Policy │
│    Compliance      │ registered Principal Entity & Header │ Schema     │
│                    │ IDs prior to gateway transmission.   │ Linter     │
└────────────────────┴──────────────────────────────────────┴────────────┘
```

---

## 5. Version 4: Websites, SaaS Platform, Stripe Payments & Dedicated Mobile Apps

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
│ 2. Stripe-First    │ Server-side webhook HMAC signature   │ Cryptograph│
│    Payment Capture │ verification marks fee cleared;      │ Signature  │
│                    │ Stripe Billing handles recurring subs│ Test       │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 3. Dedicated       │ Build pipelines (EAS/Fastlane)       │ Device Lab │
│    Branded Mobile  │ successfully generate standalone     │ & Build    │
│    Applications    │ branded binaries per institute.      │ Pipeline   │
│                    │ Offline attendance syncs cleanly.    │ Audit      │
├────────────────────┼──────────────────────────────────────┼────────────┤
│ 4. SaaS Billing &  │ Plan student quotas enforced;        │ Stripe     │
│    Entitlements    │ expired subscription triggers 15-day │ Webhook    │
│                    │ grace period then Read-Only mode.    │ Simulator  │
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
└────────────────────┴──────────────────────────────────────┴────────────┘
```
