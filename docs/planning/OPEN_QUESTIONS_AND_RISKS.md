# InstituteOS — Open Questions, Technical Risks & Decision Matrix

**Document Version:** 1.0.0  
**Status:** Architectural Audit & Risk Register  
**Priority Hierarchy:** Critical Blockers -> High Architectural Risks -> Operational Decisions  

---

## 1. Prioritized Blocker Registry (Decisions Requiring Stakeholder Approval)

Before implementation of specific versions can commence, the following architectural choices require explicit stakeholder sign-off:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        BLOCKER DECISION MATRIX                         │
├────┬─────────────────────────────┬───────────────────────┬─────────────┤
│ ID │ DECISION TOPIC              │ OPTIONS & TRADE-OFFS  │ IMPACT      │
├────┼─────────────────────────────┼───────────────────────┼─────────────┤
│B-01│ Primary Payment Gateway for │ A) Razorpay (Optimized│ Blocks V2   │
│    │ Indian Operations (V2 & V4) │    for India UPI/NEFT)│ Online Fee  │
│    │                             │ B) Stripe (Global)    │ Integration │
│    │                             │ *Recommendation: A*   │             │
├────┼─────────────────────────────┼───────────────────────┼─────────────┤
│B-02│ Attendance Override Scope   │ A) Institute-wide only│ Blocks V3   │
│    │ Hierarchy (V3)              │ B) Branch-level overrides Academic   │
│    │                             │ *Recommendation: A in │ Schema      │
│    │                             │  V2, add B in V3*     │             │
├────┼─────────────────────────────┼───────────────────────┼─────────────┤
│B-03│ Mobile App Distribution     │ A) Single unified app │ Blocks V4   │
│    │ Architecture (V4)           │ B) Separate white-label Mobile App│
│    │                             │    store apps         │ Publishing  │
│    │                             │ *Recommendation: A*   │ Strategy    │
├────┼─────────────────────────────┼───────────────────────┼─────────────┤
│B-04│ SMS Telecom Compliance      │ A) BYO DLT Gateway    │ Blocks V3   │
│    │ Strategy for India (V3)     │ B) Platform pooled SMS│ Outbound    │
│    │                             │ *Recommendation: A*   │ SMS Worker  │
├────┼─────────────────────────────┼───────────────────────┼─────────────┤
│B-05│ Background Worker Engine    │ A) Inngest (Serverless│ Blocks V2-V3│
│    │ Selection (V2–V3)           │ B) pg-boss (In-DB)    │ Background  │
│    │                             │ *Recommendation: A*   │ Queue       │
└────┴─────────────────────────────┴───────────────────────┴─────────────┘
```

---

## 2. Unrecovered Historical Questions (Q1–100 Audit Log)

Because prior interactive conversation logs were unrecovered in the local workspace, the following operational details are categorized as **Unresolved** to prevent fabricating assumptions:

### Category 1: SaaS Administration & Commercial Packaging
- **Q-UNREC-01 (Grace Period Length):** What is the exact default grace period duration between subscription payment failure and Read-Only mode? *(Proposed: 15 days).*
- **Q-UNREC-02 (Student Quota Metric):** Does the subscription student limit count total enrolled students in the database or only active students in the current academic year? *(Proposed: Active enrolled students in current academic year).*
- **Q-UNREC-03 (Trial Expiration Data Hold):** After how many days of inactive trial status should tenant workspaces be archived? *(Proposed: 30 days after trial ends).*

### Category 2: Academic & Attendance Nuances
- **Q-UNREC-04 (Attendance Holiday Rules):** Can teachers mark attendance on public holidays or official term breaks? *(Proposed: System blocks attendance on holidays unless an administrative "Emergency Class" flag is toggled).*
- **Q-UNREC-05 (Cross-Branch Student Transfer):** When a student transfers from Branch 1 to Branch 2 within the same institute, does historical attendance move or remain locked in Branch 1? *(Proposed: Historical attendance stays immutably attached to Branch 1; new attendance logs to Branch 2).*
- **Q-UNREC-06 (Grade Lock Grace Period):** How many days after an examination can a teacher modify marks before administrative unlock is required? *(Proposed: 48 hours after formal marks submission).*

### Category 3: Financial & Accounting Rules
- **Q-UNREC-07 (Cheque Bounce Fine Automation):** Should the system automatically append a configurable dishonour fine to the student fee ledger when a cheque is marked bounced? *(Proposed: Configurable toggle at institute level).*
- **Q-UNREC-08 (Financial Year Alignment):** Does the financial year follow the Indian statutory fiscal year (April 1 to March 31) or align with the academic year? *(Proposed: General Ledger runs strictly April 1 to March 31; fee structures map to academic years).*

---

## 3. High-Priority Technical & Operational Risks

### Risk 1: PostgreSQL RLS Performance at Enterprise Scale
- **Risk Description:** As tables (`attendance_records`, `journal_lines`) reach millions of rows, complex RLS sub-queries (`has_branch_access()`) could trigger sequential table scans, degrading dashboard load times.
- **Probability:** Medium | **Impact:** High
- **Mitigation:**
  - Prefix all database indexes with `institute_id` (e.g. `CREATE INDEX ON attendance_records (institute_id, branch_id, attendance_date)`).
  - Use `SECURITY DEFINER` helper functions marked `STABLE` to allow PostgreSQL query planner to cache JWT claim evaluations per transaction.

### Risk 2: Supabase Free Tier Inactivity Pause
- **Risk Description:** Supabase Free Tier projects automatically pause after 7 consecutive days without database queries. A paused database during development or pilot testing causes application connection errors.
- **Probability:** High | **Impact:** Medium
- **Mitigation:**
  - Configure a scheduled GitHub Actions cron job or UptimeRobot health check that executes a lightweight query (`SELECT 1`) every 24 hours to keep the development instance awake.
  - Upgrade to Supabase Pro ($25/month) prior to onboarding paying customer pilots.

### Risk 3: Apple App Store Guideline 4.2.6 (White-Label App Rejections)
- **Risk Description:** Apple App Store Review Guideline 4.2.6 explicitly states: *"Apps created from a commercialized template or app generation service will be rejected unless they are submitted under an account that belongs to the client organization."*
- **Probability:** Critical (for white-label individual apps) | **Impact:** High
- **Mitigation:**
  - Enforce ADR-008: Release a single unified multi-tenant app ("InstituteOS") under our company developer account. Institutes access their portal via institution code or dynamic subdomain login.
  - Do not offer separate standalone App Store listings to standard tier institutes.

### Risk 4: Indian Telecom DLT Registration Friction
- **Risk Description:** Sending SMS to Indian mobile numbers mandates Distributed Ledger Technology (DLT) registration under Telecom Regulatory Authority of India (TRAI) guidelines. Institutes may experience weeks of delay obtaining Entity IDs and registering sender headers.
- **Probability:** High | **Impact:** Medium
- **Mitigation:**
  - Provide out-of-the-box WhatsApp Business and Email notifications as primary defaults while institute DLT registration is pending.
  - Offer detailed step-by-step DLT documentation in the onboarding documentation.

---

## 4. Conflict Resolution & Consistency Auditing

| Document / Area | Potential Conflict Identified | Architectural Resolution Enforced |
| :--- | :--- | :--- |
| **Attendance Scope** | Prompt allows attendance rules at institute level; mentions possible branch overrides. | Enforce Institute-wide rules in V1–V2; introduce optional branch-level override hierarchy in V3. |
| **Financial Ledgers** | V2 requests payment receipts & dues; V5 requests double-entry general ledger. | V2 delivers operational cash receipting and student balance tracking; V5 introduces balanced Chart of Accounts and journal lines. |
| **Parent Identity** | Prompt specifies shared student/parent credentials; users might expect separate parent accounts. | Strictly maintain single shared credential for V1–V5 with explicit non-repudiation risk documentation. |
