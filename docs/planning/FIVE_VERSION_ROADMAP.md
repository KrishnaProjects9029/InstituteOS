# InstituteOS — Strict Five-Version Implementation Roadmap

**Document Version:** 1.1.0 (Remediated Baseline)  
**Status:** Approved Architectural Blueprint  
**Governance Constraint:** Exactly 5 Implementation Versions (V1–V5). No V6.  
**Approved Baseline Decisions:**  
1. **Stripe First:** Primary payment gateway integration.
2. **Separate Branded Mobile Apps:** Dedicated Android/iOS apps for every institute in V4.
3. **Dual SMS Modes:** Both BYO carrier credentials and InstituteOS-Managed pooled credits in V3.
4. **Attendance Inheritance in V1:** Full Institute → Branch → Course → Class rule inheritance delivered in V1.

---

## 1. Roadmap Executive Summary & Rules of Governance

The InstituteOS platform implementation is governed by a strict, non-negotiable **Five-Version Roadmap**. To prevent scope creep, architectural debt, and premature infrastructure costs, every feature is assigned to exactly one primary version for foundational release, with clear exit gates before the subsequent version may commence.

### Non-Negotiable Roadmap Invariants
1. **Exactly Five Versions:** The project roadmap terminates at V5. No V6 will be planned. Any features not fitting into V1–V5 must be explicitly marked as **Deferred** beyond the core product release.
2. **Audit & Acceptance Gate:** Development on Version \(N+1\) cannot begin until Version \(N\) undergoes a formal security, functional, and performance audit with explicit stakeholder sign-off.
3. **Free-Tier-First Cost Model:** V1 through V3 are architected to operate entirely within free/low-cost development tiers. Paid infrastructure (production compute, dedicated domains, SMS credits, mobile app store licenses) is introduced only where strictly necessary in V4 and V5.

---

## 2. Master Version Progression Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       INSTITUTE-OS FIVE-STAGE LIFECYCLE                     │
├─────────────┬─────────────┬──────────────┬──────────────┬───────────────────┤
│     V1      │     V2      │      V3      │      V4      │        V5         │
│    CORE     │    DAILY    │  ACADEMICS & │   WEBSITES   │    PRODUCTION     │
│  FOUNDATION │ OPERATIONS  │COMMUNICATION │ & PLATFORM   │     HARDENING     │
├─────────────┼─────────────┼──────────────┼──────────────┼───────────────────┤
│ • Tenant Org│ • Student   │ • Academic   │ • Website    │ • Double-Entry GL │
│ • Branch RLS│   Admissions│   Hierarchy  │   Builder    │ • Full GST Engine │
│ • Auth/IAM  │ • Staff HR  │ • Timetables │ • Custom     │ • DPDP Privacy    │
│ • Attendance│ • Batches   │ • Exams/Marks│   Domains    │ • Legal Holds     │
│   Inherit.  │ • Daily/    │ • Report     │ • SaaS Plans │ • High-Scale Load │
│   (V1 Core) │   Period Att│   Cards      │   & Billing  │ • Disaster Recovery│
│ • Migration │ • Fee Plans │ • Homework   │ • Stripe 1st │ • Final Security  │
│   Baseline  │ • Receipts  │ • Dual SMS   │ • Dedicated  │   Pen-Testing     │
│ • Shell UI  │ • CSV Import│   (BYO + Mgt)│   Branded    │ • Production Exit │
│ • Audit Log │             │ • Notices    │   Mobile Apps│                   │
└─────────────┴─────────────┴──────────────┴──────────────┴───────────────────┘
```

---

## 3. Detailed Version Breakdown

### Version 1: Core Foundation & Multi-Tenant Infrastructure

#### Objective
Establish the bulletproof multi-tenant core, logical tenant isolation with PostgreSQL Row-Level Security (RLS), authentication, role-based access control, design system, database migrations, immutable audit logging, and the **complete Attendance-Rule Hierarchical Inheritance Engine**.

#### Modules Delivered in V1
1. **Tenant & Organization Hierarchy:** `institutes`, `branches`, and organizational configurations.
2. **Identity & Access Management (IAM):** Role hierarchy (Owner, Admin, Branch Manager, Teacher, Accountant, Receptionist, Student), session management, password reset, and scoped branch assignments.
3. **Attendance-Rule Hierarchical Inheritance Engine:** Mandatory V1 delivery of the 4-tier rule inheritance model:
   $$\text{Institute Default} \longrightarrow \text{Branch Override} \longrightarrow \text{Course Override} \longrightarrow \text{Class Override}$$
   Evaluation precedence: **Class > Course > Branch > Institute**. Includes deterministic resolution function `resolve_effective_attendance_rule()`, validation constraints, audit history table, and RLS policies.
4. **Coherent Academic Reference Entities:** Baseline `courses` and `classes` tables supporting the attendance inheritance hierarchy.
5. **Database Schema & Migrations:** Forward-only PostgreSQL migrations with composite indexes prefixed with `institute_id`.
6. **PostgreSQL Row-Level Security (RLS) & Access Hardening:** Complete read/insert/update/delete policies; `FORCE ROW LEVEL SECURITY` applied across tenant tables; branch managers restricted to assigned branches.
7. **Hardened Audit Logging:** System audit log table with row-level `BEFORE UPDATE/DELETE` and statement-level `BEFORE TRUNCATE` triggers set to `ENABLE ALWAYS`.
8. **Shared Design System & Shell UI:** Next.js App Router shell with responsive navigation, accessible shadcn/ui components, and language selector skeleton.
9. **CI/CD & Synthetic Test Harness:** GitHub Actions pipeline running unit tests, database migrations, and negative cross-tenant isolation test suites.

---

### Version 2: Daily Operations, Admissions & Financial Tracking

#### Objective
Deliver the core operational engine required for an educational institute's day-to-day workflow: student admissions, staff registries, operational batches, daily/period attendance recording evaluated against V1 attendance rules, fee collections, and immutable receipt generation.

#### Modules Delivered in V2
1. **Student Lifecycle & Admissions:** Enquiry capture, application form, document verification, enrollment into courses/divisions, student profile management.
2. **Staff Registry & Branch Assignments:** Faculty and administrative staff records, multi-branch assignments, contact details, and department allocations.
3. **Batches & Operational Scheduling:** Creation of coaching/class batches, capacity limits, teacher assignment, and basic calendar schedules.
4. **Attendance Tracking Engine:** Daily and period-wise student attendance recording, evaluated against the V1 attendance-rule inheritance engine (minimum percentage checks, absence alert triggers).
5. **Fee Structure & Schedules:** Configurable fee plans, recurring installment schedules, discounts/scholarships, and fine rules.
6. **Payment Collection & Receipts:** Multi-channel offline recording (Cash, UPI, Cheque, Bank Transfer), automated receipt numbering, tamper-proof PDF receipt generation.
7. **Dues & Balance Engine:** Real-time calculation of student outstanding balances, installment due dates, and defalcation reports.
8. **Bulk CSV/Excel Import:** Bulk onboarding of existing student profiles, parent contacts, and opening fee balances with duplicate validation.

---

### Version 3: Academics, Timetables & Dual-Mode Omnichannel Communications

#### Objective
Enable complete academic management—grading, examinations, homework, and conflict-free timetables—coupled with automated, omnichannel parent/student notifications supporting **both BYO credentials and InstituteOS-Managed SMS credits**.

#### Modules Delivered in V3
1. **Academic Hierarchy & Rules:** Academic year transitions, courses, semesters, subjects, elective mappings, and passing mark rules.
2. **Timetable & Facility Allocation:** Weekly timetable builder with automatic collision detection for teachers, classrooms, and batches.
3. **Examinations & Marksheets:** Exam scheduling, question bank repository, marks entry with validation boundaries, and GPA/percentage grade calculation.
4. **Report Card Generator:** Automated PDF report card engine with customizable grading scales, teacher remarks, and digital signature placeholders.
5. **Homework & Digital Assignments:** Teacher homework assignment creation, due date tracking, student file submission, and teacher feedback.
6. **Dual-Mode SMS & Omnichannel Notification Engine:**
   - **Mode A (BYO):** Encrypted credential vault (AES-256-GCM) for institute-supplied Twilio/Gupshup/AWS SNS API keys.
   - **Mode B (InstituteOS-Managed):** Platform-managed SMS credit pools, automated credit consumption ledger, delivery tracking, quotas, and DLT routing.
   - Also supports In-App alerts, transactional Email (Resend), and WhatsApp messaging.
7. **Academic Calendar & Events:** Master institute calendar tracking terms, holidays, examination dates, and parent-teacher meetings.
8. **Mobile Backend API Readiness:** Versioned REST endpoints (`/api/v1/...`) supporting future mobile app authentication, push notifications, and data synchronization.

---

### Version 4: Public Websites, SaaS Platform, Stripe Payments & Dedicated Branded Mobile Apps

#### Objective
Transform InstituteOS into a complete commercial SaaS platform: institute website builder with custom domains and automated SSL, subscription billing via **Stripe First**, developer APIs, and **Separate Branded Mobile Applications for Every Institute**.

#### Modules Delivered in V4
1. **Institute Public Website Builder:** No-code landing page editor for institutes showcasing courses, faculty, facilities, photo galleries, and contact information.
2. **Public Admissions & Enquiry Portal:** Embeddable public forms allowing prospective students to apply online, pay application fees, and upload documents.
3. **Custom Domain & SSL Provisioning Engine:** Automated DNS verification, CNAME routing, and automatic SSL certificate generation via Cloudflare/Vercel.
4. **Platform SaaS Subscription Engine:** Platform Super Admin billing module managing institute subscription plans, usage metering, and billing cycles.
5. **Stripe-First Online Payment Gateway:** Primary online fee and subscription payments via Stripe API, Stripe Elements, and verified webhooks, built on an extensible `PaymentGatewayAdapter` interface.
6. **Dedicated Branded Mobile Applications (iOS & Android):**
   - Every institute receives its own branded mobile app listed in app stores.
   - Built on a shared, maintainable React Native / Expo codebase with parameterized theme tokens, logos, and institute configuration.
   - Automated multi-tenant CI/CD publishing pipelines using Fastlane and Expo Application Services (EAS).
   - Supports offline attendance caching (with strict rule: zero offline payment confirmation).
7. **Developer API Sandbox & Webhooks:** Scoped API key issuance (`inst_live_...`), rate-limited REST endpoints, and signed outbound webhooks.

---

### Version 5: Production Hardening, Enterprise Finance & Compliance

#### Objective
Harden the entire platform for enterprise scale, financial auditability, legal compliance, and disaster resilience: full double-entry general ledger, Indian GST compliance, DPDP/GDPR privacy workflows, high-concurrency load testing, and verified disaster recovery runbooks.

#### Modules Delivered in V5
1. **Double-Entry General Ledger:** Formal Chart of Accounts, automated balanced debit/credit journal postings for all transactions, trial balance, P&L, and balance sheet.
2. **Indian GST & Regional Tax Compliance:** Automated calculation of CGST, SGST, IGST, HSN/SAC codes, tax invoicing, and GST return export summaries.
3. **Staff Payroll & Expense Processing:** Salary components (Basic, HRA, PF, Deductions), payroll approval workflows, payslips, and vendor expense approvals.
4. **DPDP Act 2023 & GDPR Privacy Compliance:** Student personal data export, consent management, anonymization pipelines, and guardian verification workflows.
5. **Data Retention & Legal Holds:** Automated policy-driven data archival, configurable retention periods, and court/audit legal hold freezing mechanisms.
6. **High-Scale Load & Stress Hardening:** Database query tuning, connection pooling optimization (Supavisor), Redis caching, and simulated 10,000 concurrent user load testing.
7. **Disaster Recovery & PITR Verification:** Tested Point-in-Time Recovery procedures achieving RPO < 1 hour and RTO < 4 hours; automated offsite backup replication.
8. **Final Security Pen-Testing & Audit:** Independent security audit covering RLS bypass, OWASP Top 10, privilege escalation, and formal production readiness certification.

---

## 4. Explicitly Deferred Features & Out-of-Scope Registry

To maintain focus and guarantee delivery within the 5-version constraint, the following modules are formally deferred beyond the V1–V5 roadmap:

1. **Hostel & Dormitory Management:** Bed allocation, mess billing, and night curfew tracking.
2. **Fleet GPS Real-Time Telematics:** Real-time bus tracking on maps, driver mobile tracking, and fuel sensor integration.
3. **Advanced Library RFID & Barcode Gate Antennas:** Physical hardware turnstile integrations.
4. **Online Proctored Examination Engine:** AI webcam face-tracking and lockdown browser technology.
5. **Multi-Currency Global Cross-Border Tax Engine:** Multi-currency currency fluctuation ledgering.
