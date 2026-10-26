# InstituteOS — Architecture Decision Records (ADRs)

**Document Version:** 1.0.0  
**Status:** Approved Architectural Baseline  
**Format:** Michael Nygard ADR Standard  

---

## Index of Architecture Decision Records

- [ADR-001: Architecture Style — Modular Monolith over Microservices](#adr-001-architecture-style--modular-monolith-over-microservices)
- [ADR-002: Multi-Tenancy Strategy — Shared Database with PostgreSQL RLS](#adr-002-multi-tenancy-strategy--shared-database-with-postgresql-rls)
- [ADR-003: Core Backend & Data Platform — Supabase PostgreSQL & Supabase Auth](#adr-003-core-backend--data-platform--supabase-postgresql--supabase-auth)
- [ADR-004: Web Frontend Framework — Next.js App Router & React 19](#adr-004-web-frontend-framework--nextjs-app-router--react-19)
- [ADR-005: Student / Parent Authentication — Unified Shared Credential Model](#adr-005-student--parent-authentication--unified-shared-credential-model)
- [ADR-006: Financial Transaction Architecture — Double-Entry General Ledger](#adr-006-financial-transaction-architecture--double-entry-general-ledger)
- [ADR-007: Mobile Application Architecture — React Native / Expo](#adr-007-mobile-application-architecture--react-native--expo)
- [ADR-008: Branded Mobile App Strategy — Unified Multi-Tenant App in V4](#adr-008-branded-mobile-app-strategy--unified-multi-tenant-app-in-v4)
- [ADR-009: Background Job Execution — Inngest / Durable Serverless Queue](#adr-009-background-job-execution--inngest--durable-serverless-queue)
- [ADR-010: AI Provider Integration — Bring-Your-Own-Key with PII Anonymization](#adr-010-ai-provider-integration--bring-your-own-key-with-pii-anonymization)

---

### ADR-001: Architecture Style — Modular Monolith over Microservices

- **Status:** **APPROVED** (Mandated by Non-Negotiable Rule 11)
- **Context:** InstituteOS encompasses admissions, academic scheduling, attendance, fee collections, accounting, communications, and public websites. We must determine the optimal architectural pattern to deliver V1–V5 rapidly without runaway infrastructure costs.
- **Decision:** Build InstituteOS as a strictly structured **Modular Monolith** in Next.js, with distinct domain folders under `src/modules/` communicating via clean public interfaces and domain events.
- **Consequences:**
  - *Positive:* ACID database transactions across academic and financial workflows; zero network latency between services; simplified local testing and CI/CD; $0 development infrastructure cost.
  - *Negative:* Monolith codebase must be strictly governed to prevent developers from bypassing domain boundaries and directly coupling module tables.
- **Alternatives Considered:**
  - *Microservices Architecture:* Rejected due to excessive operational complexity, high hosting costs (multiple Kubernetes/container instances), and distributed transaction (two-phase commit) failure modes.

---

### ADR-002: Multi-Tenancy Strategy — Shared Database with PostgreSQL RLS

- **Status:** **APPROVED** (Mandated by Non-Negotiable Rule 4)
- **Context:** The platform must serve hundreds of institutes, each with multiple branches, while guaranteeing total data isolation, high query performance, and straightforward backup management.
- **Decision:** Implement a **Shared Database, Shared Schema** model with tenant isolation enforced strictly at the database engine level via **PostgreSQL Row-Level Security (RLS)**. Every tenant-owned table includes an `institute_id` foreign key.
- **Consequences:**
  - *Positive:* Single database simplifies migrations, indexing, and connection pooling; cost-effective resource sharing on free/low-cost tiers; instant cross-tenant reporting for Platform Super Admins.
  - *Negative:* All developers must understand RLS policy syntax; queries executed without proper session context return empty sets; service-role keys must be quarantined.
- **Alternatives Considered:**
  - *Database-per-Tenant:* Rejected due to prohibitive operational costs (cannot run on free tiers; provisioning separate databases for hundreds of small tuition classes is cost-prohibitive).
  - *Schema-per-Tenant:* Rejected due to PostgreSQL schema migration performance degradation when managing hundreds of tenant schemas.

---

### ADR-003: Core Backend & Data Platform — Supabase PostgreSQL & Supabase Auth

- **Status:** **APPROVED**
- **Context:** Need an enterprise-grade relational database with native RLS, real-time capabilities, managed authentication, and an object storage engine that fits the free-tier-first model.
- **Decision:** Standardize on **Supabase** (PostgreSQL 15+, Supabase Auth with custom JWT claims, Supabase Storage, and Supavisor connection pooling).
- **Consequences:**
  - *Positive:* Native integration between Auth JWT and PostgreSQL RLS session variables; built-in connection pooling handles serverless spikes; generous free tier for V1–V3 development.
  - *Negative:* Vendor dependency on Supabase extensions; free tier database pauses after 7 days of inactivity (requires keep-alive ping or upgrade to Pro in production).
- **Alternatives Considered:**
  - *Self-Hosted PostgreSQL on AWS EC2:* Rejected due to high ongoing maintenance overhead, lack of built-in auth, and lack of free tier.

---

### ADR-004: Web Frontend Framework — Next.js App Router & React 19

- **Status:** **APPROVED**
- **Context:** Need an accessible, high-performance web framework capable of rendering dynamic public marketing websites (SEO critical), rich authenticated dashboards, and server-side mutations.
- **Decision:** Use **Next.js 15+ App Router** with React 19, TypeScript (strict), Tailwind CSS, and shadcn/ui.
- **Consequences:**
  - *Positive:* React Server Components (RSC) drastically reduce client JavaScript bundle size; Server Actions provide end-to-end type safety for data mutations; built-in edge middleware simplifies dynamic multi-tenant custom domain routing.
  - *Negative:* Server Actions require careful CSRF and session re-validation; developers must strictly understand the boundary between Server and Client Components.
- **Alternatives Considered:**
  - *Vite SPA + Express Backend:* Rejected due to inferior SEO for public institute websites and lack of unified type-safe RPC conventions.

---

### ADR-005: Student / Parent Authentication — Unified Shared Credential Model

- **Status:** **APPROVED** (Mandated by Non-Negotiable Rule 5.B)
- **Context:** Educational platforms traditionally face friction when requiring separate credentials for young students and non-technical parents.
- **Decision:** Implement a **single unified login credential per enrolled student**, shared between the student and authorized parents. Do not build separate parent login accounts in the initial release.
- **Consequences:**
  - *Positive:* Minimizes credential loss and support overhead; eliminates complex parent-student account linking workflows; simplifies database schema.
  - *Negative:* **Inability to distinguish physical actor** in audit logs (cannot prove whether student or parent performed an action); out-of-band communication (SMS/WhatsApp) required for legally binding notifications.
- **Alternatives Considered:**
  - *Separate Parent & Student Accounts:* Formally deferred beyond V5 in accordance with user rules.

---

### ADR-006: Financial Transaction Architecture — Double-Entry General Ledger

- **Status:** **APPROVED** (Scheduled for V5; Foundation in V2)
- **Context:** Educational institutions require rigorous financial integrity, auditability, and tax compliance (e.g. Indian GST).
- **Decision:** Enforce **Double-Entry Bookkeeping** for the financial ledger (`journal_entries` and `journal_lines`). Financial entries are immutable and append-only. Corrections require formal credit/debit adjustment entries.
- **Consequences:**
  - *Positive:* Mathematically guarantees debits equal credits; eliminates silent balance corruption; provides real-time Trial Balance and P&L statements.
  - *Negative:* Higher development complexity than a simple single-entry cashbook; requires strict database constraint triggers.
- **Phased Implementation:** V2 implements operational payment receipts and dues tracking; V5 formalizes the full double-entry General Ledger and GST engine.

---

### ADR-007: Mobile Application Architecture — React Native / Expo

- **Status:** **APPROVED** (Scheduled for V4)
- **Context:** Staff, students, and parents require mobile access on iOS and Android devices, including offline attendance recording.
- **Decision:** Develop the mobile application using **React Native with Expo**, sharing TypeScript validation schemas, business logic, and API contracts with the Next.js web application.
- **Consequences:**
  - *Positive:* Single cross-platform codebase minimizes engineering costs; Expo provides seamless OTA (over-the-air) updates; rich ecosystem for biometric authentication and offline SQLite caching.
  - *Negative:* Native hardware integrations (e.g. specialized thermal receipt printers) require custom native modules.
- **Alternatives Considered:**
  - *Flutter:* Rejected to maintain unified TypeScript full-stack skill reuse across web and mobile.

---

### ADR-008: Branded Mobile App Strategy — Unified Multi-Tenant App in V4

- **Status:** **PROPOSED (Subject to User Review)**
- **Context:** Institutes often request dedicated white-label mobile apps with their school logo published on the Apple App Store and Google Play Store.
- **Decision:** Deliver a **single unified multi-tenant app** ("InstituteOS") in V4, where users log in using their Institute Code or Subdomain. Defer individual standalone white-label app store publishing to custom Enterprise contracts.
- **Consequences:**
  - *Positive:* Eliminates the overhead of maintaining 50+ individual developer accounts, Apple D-U-N-S registrations, and separate app store review cycles; immediate availability for all institutes.
  - *Negative:* Institutes do not get a dedicated standalone listing in the App Store search results under their own school name.
- **Alternatives Considered:**
  - *Automated White-Label App Builder:* Evaluated in Feasibility Audit; rejected for core roadmap due to strict Apple App Store Guideline 4.2.6 prohibiting templated/commercial app cloning from a single developer account.

---

### ADR-009: Background Job Execution — Inngest / Durable Serverless Queue

- **Status:** **PROPOSED**
- **Context:** Workloads such as absence SMS dispatch, bulk PDF report generation, and payment webhooks require durable, asynchronous background queues with retries and dead-letter handling.
- **Decision:** Adopt **Inngest** (or `pg-boss` / Supabase Edge Functions + `pg_cron`) for durable event-driven serverless background jobs.
- **Consequences:**
  - *Positive:* Full support for serverless execution without managing persistent worker VMs; built-in idempotency, retries, and failure observability.
  - *Negative:* Third-party dependency; free tier provides 20,000 steps/month, requiring upgrade if notification volume surges.
- **Alternatives Considered:**
  - *BullMQ with Redis:* Requires a persistent Node.js worker server running 24/7, incurring immediate hosting costs.

---

### ADR-010: AI Provider Integration — Bring-Your-Own-Key with PII Anonymization

- **Status:** **APPROVED** (Scheduled for V4)
- **Context:** AI assistance (syllabus generator, enquiry chatbot, report card remarks) adds value but presents severe privacy and API cost risks.
- **Decision:** Provide AI capabilities using **Google Gemini 1.5 Flash / OpenAI** via an architectural gateway that mandates client-side PII scrubbing and allows institutes to provide their own API keys or operate under strict monthly token caps.
- **Consequences:**
  - *Positive:* Zero AI token liability for the SaaS platform; compliance with minors' data protection rules under DPDP Act 2023.
  - *Negative:* Tenants with BYO keys must manage their own AI provider billing accounts.
