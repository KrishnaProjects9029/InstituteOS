# InstituteOS — Architecture Decision Records (ADRs)

**Document Version:** 1.1.0 (Remediated Baseline)  
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
- [ADR-008: Branded Mobile App Strategy — Dedicated Branded Apps for Every Institute](#adr-008-branded-mobile-app-strategy--dedicated-branded-apps-for-every-institute)
- [ADR-009: Background Job Execution — Inngest / Durable Serverless Queue](#adr-009-background-job-execution--inngest--durable-serverless-queue)
- [ADR-010: AI Provider Integration — Bring-Your-Own-Key with PII Anonymization](#adr-010-ai-provider-integration--bring-your-own-key-with-pii-anonymization)
- [ADR-011: Payment Gateway Strategy — Stripe First with Provider Adapters](#adr-011-payment-gateway-strategy--stripe-first-with-provider-adapters)
- [ADR-012: SMS Messaging Architecture — Dual Modes (BYO & Managed Credits)](#adr-012-sms-messaging-architecture--dual-modes-byo--managed-credits)
- [ADR-013: Attendance-Rule Hierarchical Inheritance Engine in V1](#adr-013-attendance-rule-hierarchical-inheritance-engine-in-v1)

---

### ADR-001: Architecture Style — Modular Monolith over Microservices

- **Status:** **APPROVED** (Mandated by Non-Negotiable Rule 11)
- **Context:** InstituteOS encompasses admissions, academic scheduling, attendance, fee collections, accounting, communications, and public websites. We must determine the optimal architectural pattern to deliver V1–V5 rapidly without runaway infrastructure costs.
- **Decision:** Build InstituteOS as a strictly structured **Modular Monolith** in Next.js, with distinct domain folders under `src/modules/` communicating via clean public interfaces and domain events.
- **Consequences:**
  - *Positive:* ACID database transactions across academic and financial workflows; zero network latency between services; simplified local testing and CI/CD; $0 development infrastructure cost.
  - *Negative:* Monolith codebase must be strictly governed to prevent developers from bypassing domain boundaries and directly coupling module tables.

---

### ADR-002: Multi-Tenancy Strategy — Shared Database with PostgreSQL RLS

- **Status:** **APPROVED** (Mandated by Non-Negotiable Rule 4)
- **Context:** The platform must serve hundreds of institutes, each with multiple branches, while guaranteeing total data isolation, high query performance, and straightforward backup management.
- **Decision:** Implement a **Shared Database, Shared Schema** model with tenant isolation enforced strictly at the database engine level via **PostgreSQL Row-Level Security (RLS)** with `FORCE ROW LEVEL SECURITY`. Every tenant-owned table includes an `institute_id` foreign key.
- **Consequences:**
  - *Positive:* Single database simplifies migrations, indexing, and connection pooling; cost-effective resource sharing on free/low-cost tiers; instant cross-tenant reporting for Platform Super Admins.
  - *Negative:* All developers must understand RLS policy syntax; queries executed without proper session context return empty sets; service-role keys must be quarantined.

---

### ADR-003: Core Backend & Data Platform — Supabase PostgreSQL & Supabase Auth

- **Status:** **APPROVED**
- **Context:** Need an enterprise-grade relational database with native RLS, real-time capabilities, managed authentication, and an object storage engine that fits the free-tier-first model.
- **Decision:** Standardize on **Supabase** (PostgreSQL 15+, Supabase Auth with custom JWT claims, Supabase Storage, and Supavisor connection pooling).

---

### ADR-004: Web Frontend Framework — Next.js App Router & React 19

- **Status:** **APPROVED**
- **Context:** Need an accessible, high-performance web framework capable of rendering dynamic public marketing websites (SEO critical), rich authenticated dashboards, and server-side mutations.
- **Decision:** Use **Next.js 15+ App Router** with React 19, TypeScript (strict), Tailwind CSS, and shadcn/ui.

---

### ADR-005: Student / Parent Authentication — Unified Shared Credential Model

- **Status:** **APPROVED** (Mandated by Non-Negotiable Rule 5.B)
- **Context:** Educational platforms traditionally face friction when requiring separate credentials for young students and non-technical parents.
- **Decision:** Implement a **single unified login credential per enrolled student**, shared between the student and authorized parents. Do not build separate parent login accounts in the initial release.

---

### ADR-006: Financial Transaction Architecture — Double-Entry General Ledger

- **Status:** **APPROVED** (Scheduled for V5; Foundation in V2)
- **Context:** Educational institutions require rigorous financial integrity, auditability, and tax compliance (e.g. Indian GST).
- **Decision:** Enforce **Double-Entry Bookkeeping** for the financial ledger (`journal_entries` and `journal_lines`). Financial entries are immutable and append-only. Corrections require formal credit/debit adjustment entries.

---

### ADR-007: Mobile Application Architecture — React Native / Expo

- **Status:** **APPROVED** (Scheduled for V4)
- **Context:** Staff, students, and parents require mobile access on iOS and Android devices, including offline attendance recording.
- **Decision:** Develop the mobile application using **React Native with Expo**, sharing TypeScript validation schemas, business logic, and API contracts with the Next.js web application.

---

### ADR-008: Branded Mobile App Strategy — Dedicated Branded Apps for Every Institute

- **Status:** **APPROVED (Approved Planning Decision 2)**
- **Context:** Institutes require dedicated, individually branded mobile apps listed in the Apple App Store and Google Play Store under their own school identity, logo, and name.
- **Decision:** In **Version 4**, deliver **Separate Branded Mobile Applications for Every Institute**. The architecture employs a shared, maintainable core React Native / Expo codebase with parameterized white-label asset injection, unique app bundle IDs (`com.instituteos.client.{slug}`), custom app icons/splash screens, and automated continuous delivery pipelines (Fastlane & Expo Application Services - EAS) for multi-tenant app store release management.
- **Consequences:**
  - *Positive:* Satisfies institute brand identity; direct app store discovery; full native customization.
  - *Negative:* Requires managing release pipelines for multiple app listings; requires navigating Apple Developer Program guidelines (Guideline 4.2.6) via client developer accounts or authorized B2B Custom App distribution.

---

### ADR-009: Background Job Execution — Inngest / Durable Serverless Queue

- **Status:** **APPROVED**
- **Context:** Workloads such as absence SMS dispatch, bulk PDF report generation, and payment webhooks require durable, asynchronous background queues with retries and dead-letter handling.
- **Decision:** Adopt **Inngest** (or Supabase Edge Functions + `pg_cron`) for durable event-driven serverless background jobs.

---

### ADR-010: AI Provider Integration — Bring-Your-Own-Key with PII Anonymization

- **Status:** **APPROVED** (Scheduled for V4)
- **Context:** AI assistance (syllabus generator, enquiry chatbot, report card remarks) adds value but presents severe privacy and API cost risks.
- **Decision:** Provide AI capabilities using **Google Gemini 1.5 Flash / OpenAI** via an architectural gateway that mandates client-side PII scrubbing and allows institutes to provide their own API keys or operate under strict monthly token caps.

---

### ADR-011: Payment Gateway Strategy — Stripe First with Provider Adapters

- **Status:** **APPROVED (Approved Planning Decision 1)**
- **Context:** The platform requires secure online payment processing for student tuition, application fees, and SaaS subscriptions.
- **Decision:** **Stripe is the first-priority payment gateway.** All payment flows (checkout, customer portal, webhooks, recurring subscriptions) integrate against Stripe API / Stripe Elements first, implemented behind an extensible `PaymentGatewayAdapter` interface (`StripeAdapter`, with future adapters for regional gateways).
- **Consequences:**
  - *Positive:* World-class developer ergonomics, unified international recurring subscription engine (Stripe Billing), robust webhook signatures, and rapid prototyping.
  - *Verification Caveat:* Stripe in India operates under RBI regulations (e.g. e-mandate guidelines, international card settlement restrictions, export declarations). Implementation must verify supported domestic payment rails (e.g. cards vs domestic UPI) and not assume every global Stripe feature is available to Indian merchants without verification.

---

### ADR-012: SMS Messaging Architecture — Dual Modes (BYO & Managed Credits)

- **Status:** **APPROVED (Approved Planning Decision 3)**
- **Context:** Automated parent and student notifications (attendance alerts, fee reminders) require reliable SMS delivery while balancing telecom compliance and platform operating margin.
- **Decision:** Support **BOTH SMS operational modes**:
  1. **Bring-Your-Own (BYO) Provider:** Institutes configure their own carrier credentials (e.g. Twilio, Gupshup, AWS SNS) via an encrypted credential vault (AES-256-GCM).
  2. **InstituteOS-Managed SMS:** Institutes purchase platform-managed SMS credit pools. The platform handles telecom routing, carrier failover, Indian DLT registration compliance, usage ledgering, and quota enforcement.
- **Consequences:**
  - *Positive:* Maximum flexibility: large institutes with existing carrier contracts can use BYO, while smaller coaching centres can start immediately using managed credits.
  - *Negative:* Platform-managed mode requires maintaining an internal SMS credit ledger, automated top-ups, and managing DLT telemarketing entity compliance.

---

### ADR-013: Attendance-Rule Hierarchical Inheritance Engine in V1

- **Status:** **APPROVED (Approved Planning Decision 4)**
- **Context:** Educational institutions require fine-grained attendance policies (minimum percentage, consecutive absence warnings, late grace minutes, half-day thresholds) that vary across campuses, courses, and individual classes.
- **Decision:** Deliver the complete **Attendance-Rule Hierarchical Inheritance Engine in Version 1**.
  - **Inheritance Flow:** $\text{Institute Default} \longrightarrow \text{Branch Override} \longrightarrow \text{Course Override} \longrightarrow \text{Class Override}$.
  - **Evaluation Precedence:** The most specific active rule wins: **Class > Course > Branch > Institute**.
  - **Resolution Engine:** Deterministic PostgreSQL function `resolve_effective_attendance_rule()` resolving effective rules with fallback to parent tiers when child rules are absent, inactive, or invalid.
  - **Audit History:** Dedicated `attendance_rule_audit_history` table capturing every rule creation, update, and deactivation with user attribution.
- **Consequences:**
  - *Positive:* Full hierarchical policy support from day one; academic operations in V2-V3 immediately inherit robust policy enforcement without schema refactoring.
  - *Negative:* V1 must include coherent academic reference entities (`courses` and `classes`) to anchor the hierarchy.
