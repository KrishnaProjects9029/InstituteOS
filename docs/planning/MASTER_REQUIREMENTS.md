# InstituteOS — Master Requirements Specification

**Document Version:** 1.1.0 (Remediated Baseline)  
**Status:** Approved Architectural Specification  
**Classification:** Internal Technical Specification  
**Target Platform:** Multi-Tenant Education Management SaaS  
**Approved Baseline Decisions:**  
1. **Stripe First:** Primary payment gateway using provider-adapter architecture.
2. **Separate Branded Mobile Apps:** Dedicated Android and iOS applications per institute in V4.
3. **Dual SMS Modes:** Both BYO (Bring-Your-Own) carrier credentials and InstituteOS-Managed pooled credits.
4. **Attendance Inheritance in V1:** Full Institute → Branch → Course → Class rule inheritance delivered in V1.

---

## 1. Executive Summary & Purpose

InstituteOS is an enterprise-grade, multi-tenant Software-as-a-Service (SaaS) platform engineered for educational institutions ranging from single coaching centres and tuition academies to multi-branch schools, colleges, and polytechnic networks.

The primary purpose of this document is to establish an authoritative, consolidated master requirements baseline. It formalizes all functional, technical, security, financial, and operational requirements across the platform's lifecycle. It explicitly documents confirmed requirements, technical standards, and approved architectural decisions across exactly five versions (V1–V5).

---

## 2. Requirements Traceability & Status Definitions

Every requirement is tagged with a structured status:
- **Confirmed:** Explicitly mandated by project non-negotiables, core architectural decisions, or approved planning decisions.
- **Proposed:** Architecturally recommended technical standard, currently undergoing user/stakeholder review.
- **Unresolved:** Ambiguous design choice requiring explicit stakeholder confirmation before execution.
- **Deferred:** Intentionally scheduled for post-V5 enterprise roadmap or subject to separate feasibility sign-off.

---

## 3. Master Requirements Matrix

### A. SaaS Administration & Onboarding (ADM)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-ADM-001** | Super Admin Console | Dedicated platform-level administration panel for super administrators to inspect, manage, and monitor all tenant institutes. | P0 | V1 (Foundational) / V4 (Full) | System Invariant | Confirmed | Super admins can view all institutes, system telemetry, and tenant statuses; strict isolation prevents super admin leaking into tenant-level RLS without explicit audit trail. |
| **REQ-ADM-002** | Institute Verification & Onboarding | Automated and manual workflows for registering new institutes, verifying KYC/credentials, and provisioning organization workspaces. | P0 | V1 (Manual) / V4 (Self-Service) | Core Architecture | Confirmed | New tenant creation creates an isolated `institute_id` with default root branch, owner credentials, and default configuration schemas. |
| **REQ-ADM-003** | Multi-Branch Organization Hierarchy | Native support for multi-branch institutions where one central educational organization manages multiple geographic or operational campuses. | P0 | V1 | Core Architecture | Confirmed | System supports single-branch institutes and multi-branch groups seamlessly; records can be partitioned by `branch_id` or scoped globally at `institute_id`. |
| **REQ-ADM-004** | Subscription Tier Management | Tiered subscription engine supporting Free Trials, Tiered Plans (e.g., Starter, Growth, Enterprise), and hybrid feature/volume-based pricing. | P1 | V4 | Core Architecture | Confirmed | Institute access to modules, maximum student limits, and branch counts are strictly enforced via database entitlements linked to subscription status. |
| **REQ-ADM-005** | Entitlements & Metering | Real-time enforcement of plan quotas (active student count, branch count, monthly SMS credits, file storage GBs). | P0 | V4 | Core Architecture | Confirmed | System raises actionable warnings at 80% and blocks creations exceeding 100% quota with clear upgrade prompts; hard stops prevent tenant over-consumption. |
| **REQ-ADM-006** | Invoicing & Subscription Billing | Automated recurring billing, tax invoicing, automated renewal notifications, and integration with Stripe Billing. | P1 | V4 | Core Architecture | Confirmed | Generates compliant tax invoices for subscription charges; automates recurring webhook-driven charge capture via Stripe. |
| **REQ-ADM-007** | Grace Periods & Subscription Lifecycle | Configurable lifecycle transitions: Active -> Overdue -> Grace Period -> Read-Only Suspension -> Quarantine -> Exit Archive. | P0 | V4 | Non-Negotiable Rule 5.A | Confirmed | Expired subscriptions enter a configurable grace period (default 15 days), then transition to Read-Only mode; **zero silent deletion** of tenant data. |
| **REQ-ADM-008** | Self-Service Data Export on Offboarding | Authorized export utility enabling an exiting institute owner to download full academic, financial, and student data in standardized formats. | P1 | V5 | Non-Negotiable Rule 5.A | Confirmed | Institute Owner can trigger a complete encrypted archive generation (JSON/CSV + files zip) during active or read-only states prior to account termination. |

---

### B. Identity & Access Management (IAM)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-IAM-001** | Core Role Hierarchy | Fixed role definitions: Institute Owner, Institute Admin, Branch Manager, Teacher/Faculty, Accountant, Receptionist, and Student. | P0 | V1 | Core Architecture | Confirmed | All built-in roles have well-defined permission baselines; system rejects operations violating role boundaries at server and database layers. |
| **REQ-IAM-002** | Branch-Scoped Access Control | Permission evaluation dynamically scoped to the user's active branch assignment or cross-branch organizational privileges. | P0 | V1 | Core Architecture | Confirmed | Branch Managers and staff can only read/mutate data belonging to their assigned branches; **Branch Managers cannot view staff assignments in unassigned branches**. |
| **REQ-IAM-003** | Multi-Branch Staff Assignments | Ability for a single staff member (e.g. Teacher, Accountant) to hold distinct roles across multiple branches under the same institute. | P1 | V1 | Core Architecture | Confirmed | A teacher can teach in Branch A and Branch B with seamless context switching without requiring distinct login accounts. |
| **REQ-IAM-004** | Authentication & Session Revocation | Secure email/password, magic link, and OTP authentication with instant global session invalidation and token refresh mechanics. | P0 | V1 | Core Architecture | Confirmed | User passwords hashed using bcrypt/argon2; sessions can be terminated instantly by admin or user, invalidating all issued JWT refresh tokens. |
| **REQ-IAM-005** | Multi-Factor Authentication (MFA) | Configurable TOTP (authenticator app) MFA for administrative and privileged roles (Owner, Admin, Accountant). | P1 | V1 (Framework) / V5 (Enforced) | Core Architecture | Confirmed | Privileged roles can be mandated to require TOTP verification on login; backup recovery codes generated and securely hashed. |
| **REQ-IAM-006** | Shared Student/Parent Credential Model | Single unified login credential per enrolled student, shared between the student and authorized parents/guardians. | P0 | V2 | Non-Negotiable Rule 5.B | Confirmed | System exposes parent and student features under one authenticated identity; audit trail records "Student/Parent" persona with explicit disclaimer. |
| **REQ-IAM-007** | Shared Account Limitation Transparency | Systemic documentation and user warnings that actions performed on student accounts cannot reliably distinguish parent vs student actors. | P1 | V2 | Non-Negotiable Rule 5.B | Confirmed | UI and terms explicitly inform users that homework submissions, notice acknowledgments, and fee payments share the same non-repudiation boundary. |
| **REQ-IAM-008** | Prevention of Unauthorised Self-Registration | Public portal self-signup cannot grant automatic access to any existing institute's data or privileged roles. | P0 | V1 | Non-Negotiable Rule 5.B | Confirmed | Public signups can only initiate a new trial institute or submit an external admission enquiry; joining an existing institute requires an administrative invitation. |

---

### C. Academic Operations & Attendance Rules (ACA)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-ACA-001** | Student Lifecycle & Enrolment | Complete student lifecycle management: Lead -> Enquiry -> Application -> Document Verification -> Active Student -> Alumni / Transferred. | P0 | V2 | Core Architecture | Confirmed | Full historical tracking of student status; student retains a single central identity within the institute even if enrolled across branches. |
| **REQ-ACA-002** | Academic Hierarchy Management | Configurable structure of Academic Years, Terms/Semesters, Courses/Programs, Classes/Grades, Divisions/Sections, and Subjects. | P0 | V1 (Baseline Entities) / V2-V3 | Core Architecture | Confirmed | V1 provides coherent reference tables for Courses and Classes to support attendance-rule inheritance; V2-V3 expands full division and term workflows. |
| **REQ-ACA-003** | Batch & Group Management | Grouping of students into operational batches for coaching sessions, lab practicals, elective courses, and remedial classes. | P1 | V2 | Core Architecture | Confirmed | Students can belong to multiple batches; batches have designated faculty, meeting schedules, and capacity constraints. |
| **REQ-ACA-004** | Multi-Tier Attendance Engine | Flexible recording of student attendance supporting Daily (once a day), Period-wise (per timetable slot), and Session/Batch-wise. | P0 | V2 | Core Architecture | Confirmed | Attendance records track Present, Absent, Late, Excused; evaluated against effective attendance rules resolved from the inheritance engine. |
| **REQ-ACA-005** | Attendance-Rule Inheritance Engine | **Mandatory V1 Engine:** Multi-level rule inheritance supporting: **Institute Default → Branch Override → Course Override → Class Override**. | P0 | **V1** | Approved Decision 4 | **Confirmed (V1)** | Deterministic resolution: **Class > Course > Branch > Institute**. Supports minimum attendance %, consecutive absence alerts, late grace minutes, and half-day thresholds. Includes change history and RLS. |
| **REQ-ACA-006** | Timetable & Scheduling | Timetable generation and conflict detection for classes, rooms, and faculty across recurring weekly schedules. | P1 | V3 | Core Architecture | Confirmed | Timetable detects faculty double-booking and room allocation collisions; displays interactive calendar views for teachers and students. |
| **REQ-ACA-007** | Examinations & Grading | Exam scheduling, question banks, marks entry, grading scales (percentage, GPA, letter grades), and automated ranking calculation. | P1 | V3 | Core Architecture | Confirmed | Supports term exams and unit tests; marks entry includes validation ranges; prevents marks entry after formal exam lock date. |
| **REQ-ACA-008** | Report Card Generation | Automated generation of printable and downloadable PDF report cards featuring institute branding, grading tables, and remarks. | P1 | V3 | Core Architecture | Confirmed | High-performance PDF generation engine renders customizable report cards with QR-code verification. |
| **REQ-ACA-009** | Homework & Assignments | Creation, distribution, submission, grading, and feedback for student homework, including digital file attachments. | P2 | V3 | Core Architecture | Confirmed | Teachers can upload assignments with due dates; students/parents upload submissions; teachers grade and return feedback. |

---

### D. Finance & Accounting (FIN)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-FIN-001** | Fee Structure & Schedules | Definition of flexible fee plans, recurring installments, component breakdowns (Tuition, Lab, Admission), discounts, and scholarships. | P0 | V2 | Core Architecture | Confirmed | Assigns customized or batch fee plans to students; calculates net payable after approved scholarships/concessions. |
| **REQ-FIN-002** | Multi-Channel Payment Recording | Collection and recording of payments via Cash, UPI, Cheque, Bank Transfer (NEFT/RTGS), and Online Gateways. | P0 | V2 | Core Architecture | Confirmed | Cash/Cheque payments record cashier metadata; cheque collections track clearance status (Pending -> Cleared -> Bounced). |
| **REQ-FIN-003** | Stripe-First Online Payment Integration | **Stripe is the first-priority payment gateway**, architected via an extensible provider-adapter pattern to support secondary gateways. | P0 | V2 (Manual) / V4 (Online Stripe) | Approved Decision 1 | Confirmed | Primary integration via Stripe Elements & webhooks; server-side signature verification; supports cards and Stripe-supported payment rails. |
| **REQ-FIN-004** | Receipt Generation & Numbering | Automated generation of immutable payment receipts with unique sequential numbering per branch or per institute. | P0 | V2 | Core Architecture | Confirmed | System generates sequential, tamper-proof PDF receipts with institute branding; receipts cannot be deleted or re-numbered once issued. |
| **REQ-FIN-005** | Financial Corrections & Reversals | Policy prohibiting silent overwriting or deletion of financial records; corrections require explicit adjustment or reversal notes. | P0 | V2 | Non-Negotiable Rule 5.D | Confirmed | Erroneous payments are corrected via Credit Notes or formal Cancellation transactions with mandatory justification and audit logging. |
| **REQ-FIN-006** | Expense & Vendor Management | Tracking institute operational expenses, vendor invoices, payment approvals, and categorization by cost centre/branch. | P1 | V5 | Core Architecture | Confirmed | Branch and institute expenses can be logged, matched against vendor profiles, and routed through approval hierarchies. |
| **REQ-FIN-007** | Staff Payroll Management | Definition of salary components (Basic, HRA, Allowances, Deductions, PF, Tax), payroll runs, approval workflows, and payslip generation. | P1 | V5 | Core Architecture | Confirmed | Generates monthly payroll batches; enforces strict separation between payroll permissions and general academic roles. |
| **REQ-FIN-008** | Double-Entry General Ledger | Compliant double-entry bookkeeping engine with automated journal postings for fee collections, refunds, expenses, and payroll. | P1 | V5 | Core Architecture | Confirmed | Every financial event writes balanced Debit and Credit rows to `journal_lines`; provides real-time Trial Balance, P&L, and Balance Sheet. |
| **REQ-FIN-009** | Indian GST & Regional Tax Rules | Configuration of tax rules, CGST/SGST/IGST breakdowns, HSN/SAC code mapping, and GST-compliant tax invoicing. | P1 | V5 | Core Architecture | Confirmed | Invoices display institute GSTIN, recipient details, and separate CGST/SGST lines where tax applicability is configured. |

---

### E. Communications & Calendars (COM)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-COM-001** | Multi-Channel Notifications | Omnichannel delivery engine supporting In-App Notifications, Transactional Email, SMS, and WhatsApp messages. | P1 | V3 | Core Architecture | Confirmed | Users receive targeted notifications based on role, branch, and event triggers (e.g. absent notice, fee due alert). |
| **REQ-COM-002** | Dual SMS Modes (BYO & Managed) | **Support for BOTH Bring-Your-Own (BYO) credentials AND InstituteOS-Managed messaging credits.** | P1 | V3 | Approved Decision 3 | Confirmed | Tenants can plug in own Twilio/AWS SNS/DLT credentials OR purchase platform-managed SMS credit pools. Encrypted credential vault (AES-256-GCM); credit ledger; delivery logs. |
| **REQ-COM-003** | Telecom Compliance & DLT Support | Template management supporting Principal Entity (PE) ID, Header ID, and Template Registration IDs mandated by TRAI in India. | P1 | V3 | Core Architecture | Confirmed | SMS dispatch validates DLT template ID and dynamic variable bounds prior to submission to telecom gateways. |
| **REQ-COM-004** | Delivery Tracking & Retry Engine | Granular delivery status tracking (Queued, Sent, Delivered, Failed) with exponential backoff retries for transient carrier errors. | P1 | V3 | Core Architecture | Confirmed | Webhook callbacks from email/SMS gateways update status in `notification_logs`; dead-letter tracking prevents infinite retry loops. |
| **REQ-COM-005** | Quiet Hours & Opt-Out Handling | Automated enforcement of promotional communication restrictions during defined hours and respect for parent DND/opt-out preferences. | P2 | V3 | Core Architecture | Confirmed | Non-emergency/promotional notifications are queued during quiet hours (e.g. 9:00 PM to 8:00 AM) and dispatched the next morning. |
| **REQ-COM-006** | Academic Calendar & Events | Master institutional calendar tracking academic terms, examination dates, public holidays, parent-teacher meetings, and events. | P1 | V3 | Core Architecture | Confirmed | Interactive calendar feed accessible to staff and students; supports iCal/webcal export for synchronization with Google/Outlook calendars. |

---

### F. Websites & Mobile Applications (WEB / MOB)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-WEB-001** | Institute Public Website Builder | Configurable, SEO-optimized public website builder for institutes to showcase courses, faculty, branches, and facilities. | P1 | V4 | Core Architecture | Confirmed | Tenants configure hero sections, about us, course catalogs, and contact pages from a no-code visual settings panel. |
| **REQ-WEB-002** | Online Public Admissions & Enquiries | Embeddable public enquiry and admission application forms linked directly to the institute's CRM/admission pipeline. | P0 | V4 | Core Architecture | Confirmed | Prospective students can submit applications and upload documents; submissions appear instantly in the institute's admission inbox. |
| **REQ-WEB-003** | Custom Domain & SSL Automation | Automatic routing and TLS/SSL certificate lifecycle management for tenant custom domains (e.g. `admissions.apexacademy.com`). | P1 | V4 | Core Architecture | Confirmed | Tenant enters custom CNAME; system verifies DNS propagation, generates Let's Encrypt SSL via Cloudflare/Vercel, and binds domain. |
| **REQ-MOB-001** | Dedicated Branded Mobile Apps | **Every institute is intended to have its own branded Android and iOS applications** delivered in V4. | P1 | V4 | Approved Decision 2 | Confirmed | Shared core codebase (React Native/Expo) with institute-specific asset injection, theme styling, bundle IDs, and automated build pipelines (Fastlane/EAS). |
| **REQ-MOB-002** | Offline Data Caching & Sync | Local encrypted mobile database (WatermelonDB / SQLite) enabling teachers to take attendance in low-connectivity areas with sync queue. | P1 | V4 | Non-Negotiable Rule 5.F | Confirmed | Offline attendance syncs automatically upon network reconnection; conflicts resolved using server-authoritative timestamping. |
| **REQ-MOB-003** | Offline Payment Prohibition | Strict architectural invariant: payments recorded while offline are **never** treated as confirmed until verified by server. | P0 | V4 | Non-Negotiable Rule 5.F | Confirmed | Mobile clients cannot generate official payment receipts or mark fees cleared while in an offline/unauthenticated state. |

---

### G. Platform-Wide Capabilities (PLT)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-PLT-001** | Multi-Lingual Localization (i18n) | Platform UI localization supporting English, Hindi, and Marathi, with an extensible dictionary framework for additional languages. | P1 | V1 (Framework) / V3 (Complete) | Core Architecture | Confirmed | Users can switch languages dynamically; dates, numbers, and currencies format according to Indian locales (`en-IN`, `hi-IN`, `mr-IN`). |
| **REQ-PLT-002** | Accessibility Compliance (WCAG 2.2 AA) | User interface adherence to WCAG 2.2 Level AA accessibility guidelines across dashboards, forms, and contrast ratios. | P1 | V1 (Baseline) / V5 (Audit) | Core Architecture | Confirmed | Keyboard navigation, screen-reader semantic HTML, focus traps in modals, and color contrast ratios exceeding 4.5:1 verified by automated audits. |
| **REQ-PLT-003** | Global Search Engine | Unified search bar across students, staff, batches, invoices, and academic courses with branch-aware permission scoping. | P2 | V3 | Core Architecture | Confirmed | Search returns sub-second results; never leaks search hits for entities in branches or institutes the user has no permission to access. |
| **REQ-PLT-004** | Bulk CSV / Excel Import Engine | High-throughput data import engine with column mapping, schema validation, preview mode, duplicate detection, and error logging. | P1 | V2 | Core Architecture | Confirmed | Administrators can import hundreds of student/fee records; system flags invalid emails/phone numbers and outputs an error reconciliation sheet. |
| **REQ-PLT-005** | Secure Document Object Storage | Storage architecture separating file metadata in PostgreSQL from actual encrypted files stored in private S3/Supabase Storage. | P0 | V1 | Core Architecture | Confirmed | Files are stored in private buckets; direct public access is blocked; downloads require short-lived (15 min) pre-signed URLs. |

---

### H. Security, Governance & Reliability (SEC)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-SEC-001** | PostgreSQL Row-Level Security (RLS) | Comprehensive database-level RLS policies enforcing tenant and branch isolation for all reads, inserts, updates, and deletes. | P0 | V1 | Non-Negotiable Rule 4 | Confirmed | Zero data leakage between institutes; queries executed without valid JWT or matching tenant context return 0 rows; `FORCE ROW LEVEL SECURITY` applied. |
| **REQ-SEC-002** | Hardened Audit Logging | Tamper-resistant audit logging capturing sensitive mutations, guarded by `BEFORE UPDATE`, `BEFORE DELETE`, and `BEFORE TRUNCATE` triggers. | P0 | V1 | Non-Negotiable Rule 5.H | Confirmed | Audit log captures timestamp, institute_id, user_id, action, resource, ip_address, old_values, new_values; statement-level trigger blocks `TRUNCATE`. |
| **REQ-SEC-003** | DPDP Act 2023 & GDPR Privacy Compliance | Data fiduciary compliance workflows: Right to Access, Correction, Erasure, and Minor Guardian Consent management. | P1 | V5 | Non-Negotiable Rule 5.H | Confirmed | Platform supports automated generation of a student's personal data file and anonymization workflows for deleted records. |
| **REQ-SEC-004** | Legal Holds & Data Retention | Ability to place a legal hold on an institute or student account, suspending automatic record archival and deletion routines. | P1 | V5 | Non-Negotiable Rule 5.H | Confirmed | Records flagged under `legal_hold` cannot be purged by retention scripts until hold is formally removed by authorized legal role. |
| **REQ-SEC-005** | Automated Backup & Point-in-Time Recovery | Daily automated encrypted backups with Point-in-Time Recovery (PITR) to meet strict RTO (< 4 hrs) and RPO (< 1 hr) objectives. | P0 | V1 (Strategy) / V5 (Verified) | Non-Negotiable Rule 5.H | Confirmed | Production database supports continuous WAL archiving; automated recovery drills verify restoration within target RTO/RPO windows. |
| **REQ-SEC-006** | Zero Silent Deletion Guarantee | Systematic architectural barrier preventing automated or silent deletion of institute data upon subscription cancellation or payment failure. | P0 | V1 | Non-Negotiable Rule 5.A | Confirmed | Database schemas reject cascade deletes on root institute entities; offboarding requires a formal, multi-factor authenticated decommission workflow. |
