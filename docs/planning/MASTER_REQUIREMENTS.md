# InstituteOS — Master Requirements Specification

**Document Version:** 1.0.0  
**Status:** Approved for Architecture & Implementation Planning  
**Classification:** Internal Technical Specification  
**Target Platform:** Multi-Tenant Education Management SaaS  

---

## 1. Executive Summary & Purpose

InstituteOS is an enterprise-grade, multi-tenant Software-as-a-Service (SaaS) platform engineered for educational institutions ranging from single coaching centres and tuition academies to multi-branch schools, colleges, and polytechnic networks.

The primary purpose of this document is to establish an authoritative, consolidated master requirements baseline. It formalizes all functional, technical, security, financial, and operational requirements across the platform's lifecycle. It explicitly documents confirmed requirements, proposed technical standards, unresolved decisions arising from historical unrecovered sessions, and deferred features.

---

## 2. Requirements Traceability & Status Definitions

To maintain architectural integrity and auditability, every requirement is tagged with a structured status:
- **Confirmed:** Explicitly mandated by project non-negotiables, core architectural decisions, or verified user requirements.
- **Proposed:** Architecturally recommended technical standard, currently undergoing user/stakeholder review.
- **Unresolved:** Ambiguous or unrecovered design choice requiring explicit stakeholder confirmation before execution.
- **Deferred:** Intentionally scheduled for post-V5 enterprise roadmap or subject to separate feasibility sign-off.

### Historical Q1–100 Traceability Audit
Prior interactive sessions involving exploratory questions (Questions 1–100) were evaluated. Because historical conversation transcripts could not be recovered in the local workspace, all decisions not explicitly defined in the project baseline have been recorded as **Unresolved** or **Proposed**, ensuring that no decisions are silently fabricated.

---

## 3. Master Requirements Matrix

### A. SaaS Administration & Onboarding (ADM)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-ADM-001** | Super Admin Console | Dedicated platform-level administration panel for super administrators to inspect, manage, and monitor all tenant institutes. | P0 | V1 (Foundational) / V4 (Full) | System Invariant | Confirmed | Super admins can view all institutes, system telemetry, and tenant statuses; strict isolation prevents super admin leaking into tenant tenant-level RLS without explicit audit trail. |
| **REQ-ADM-002** | Institute Verification & Onboarding | Automated and manual workflows for registering new institutes, verifying KYC/credentials, and provisioning organization workspaces. | P0 | V1 (Manual) / V4 (Self-Service) | Core Architecture | Confirmed | New tenant creation creates a isolated `institute_id` with default root branch, owner credentials, and default configuration schemas. |
| **REQ-ADM-003** | Multi-Branch Organization Hierarchy | Native support for multi-branch institutions where one central educational organization manages multiple geographic or operational campuses. | P0 | V1 | Core Architecture | Confirmed | System supports single-branch institutes and multi-branch groups seamlessly; records can be partitioned by `branch_id` or scoped globally at `institute_id`. |
| **REQ-ADM-004** | Subscription Tier Management | Tiered subscription engine supporting Free Trials, Tiered Plans (e.g., Starter, Growth, Enterprise), and hybrid feature/volume-based pricing. | P1 | V4 | Core Architecture | Confirmed | Institute access to modules, maximum student limits, and branch counts are strictly enforced via database entitlements linked to subscription status. |
| **REQ-ADM-005** | Entitlements & Metering | Real-time enforcement of plan quotas (active student count, branch count, monthly SMS/WhatsApp credits, file storage GBs). | P0 | V4 | Core Architecture | Confirmed | System raises actionable warnings at 80% and blocks creations exceeding 100% quota with clear upgrade prompts; hard stops prevent tenant over-consumption. |
| **REQ-ADM-006** | Invoicing & Subscription Billing | Automated recurring billing, tax invoicing, automated renewal notifications, and integration with merchant payment gateways. | P1 | V4 | Core Architecture | Confirmed | Generates compliant tax invoices for subscription charges; automates recurring webhook-driven charge capture. |
| **REQ-ADM-007** | Grace Periods & Subscription Lifecycle | Configurable lifecycle transitions: Active -> Overdue -> Grace Period -> Read-Only Suspension -> Quarantine -> Exit Archive. | P0 | V4 | Non-Negotiable Rule 5.A | Confirmed | Expired subscriptions enter a configurable grace period (default 15 days), then transition to Read-Only mode; **zero silent deletion** of tenant data. |
| **REQ-ADM-008** | Self-Service Data Export on Offboarding | Authorized export utility enabling an exiting institute owner to download full academic, financial, and student data in standardized formats. | P1 | V5 | Non-Negotiable Rule 5.A | Confirmed | Institute Owner can trigger a complete encrypted archive generation (JSON/CSV + files zip) during active or read-only states prior to account termination. |

---

### B. Identity & Access Management (IAM)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-IAM-001** | Core Role Hierarchy | Fixed role definitions: Institute Owner, Institute Admin, Branch Manager, Teacher/Faculty, Accountant, Receptionist, and Student. | P0 | V1 | Core Architecture | Confirmed | All built-in roles have well-defined permission baselines; system rejects operations violating role boundaries at server and database layers. |
| **REQ-IAM-002** | Branch-Scoped Access Control | Permission evaluation dynamically scoped to the user's active branch assignment or cross-branch organizational privileges. | P0 | V1 | Core Architecture | Confirmed | Branch Managers and staff can only read/mutate data belonging to their assigned branches, unless explicitly assigned organization-wide privileges. |
| **REQ-IAM-003** | Multi-Branch Staff Assignments | Ability for a single staff member (e.g. Teacher, Accountant) to hold distinct roles across multiple branches under the same institute. | P1 | V1 | Core Architecture | Confirmed | A teacher can teach in Branch A and Branch B with seamless context switching without requiring distinct login accounts. |
| **REQ-IAM-004** | Authentication & Session Revocation | Secure email/password, magic link, and OTP authentication with instant global session invalidation and token refresh mechanics. | P0 | V1 | Core Architecture | Confirmed | User passwords hashed using bcrypt/argon2; sessions can be terminated instantly by admin or user, invalidating all issued JWT refresh tokens. |
| **REQ-IAM-005** | Multi-Factor Authentication (MFA) | Configurable TOTP (authenticator app) MFA for administrative and privileged roles (Owner, Admin, Accountant). | P1 | V1 (Framework) / V5 (Enforced) | Core Architecture | Confirmed | Privileged roles can be mandated to require TOTP verification on login; backup recovery codes generated and securely hashed. |
| **REQ-IAM-006** | Shared Student/Parent Credential Model | Single unified login credential per enrolled student, shared between the student and authorized parents/guardians. | P0 | V2 | Non-Negotiable Rule 5.B | Confirmed | System exposes parent and student features under one authenticated identity; audit trail records "Student/Parent" persona with explicit disclaimer. |
| **REQ-IAM-007** | Shared Account Limitation Transparency | Systemic documentation and user warnings that actions performed on student accounts cannot reliably distinguish parent vs student actors. | P1 | V2 | Non-Negotiable Rule 5.B | Confirmed | UI and terms explicitly inform users that homework submissions, notice acknowledgments, and fee payments share the same non-repudiation boundary. |
| **REQ-IAM-008** | Prevention of Unauthorised Self-Registration | Public portal self-signup cannot grant automatic access to any existing institute's data or privileged roles. | P0 | V1 | Non-Negotiable Rule 5.B | Confirmed | Public signups can only initiate a new trial institute or submit an external admission enquiry; joining an existing institute requires an administrative invitation. |

---

### C. Academic Operations (ACA)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-ACA-001** | Student Lifecycle & Enrolment | Complete student lifecycle management: Lead -> Enquiry -> Application -> Document Verification -> Active Student -> Alumni / Transferred. | P0 | V2 | Core Architecture | Confirmed | Full historical tracking of student status; student retains a single central identity within the institute even if enrolled across branches. |
| **REQ-ACA-002** | Academic Hierarchy Management | Configurable structure of Academic Years, Terms/Semesters, Courses/Programs, Classes/Grades, Divisions/Sections, and Subjects. | P0 | V2 (Basic) / V3 (Complete) | Core Architecture | Confirmed | Hierarchy supports flexible naming (e.g., "Grade 10 - Section A" or "B.Sc Computer Science - Semester 3"); changes are versioned per academic year. |
| **REQ-ACA-003** | Batch & Group Management | Grouping of students into operational batches for coaching sessions, lab practicals, elective courses, and remedial classes. | P1 | V2 | Core Architecture | Confirmed | Students can belong to multiple batches; batches have designated faculty, meeting schedules, and capacity constraints. |
| **REQ-ACA-004** | Multi-Tier Attendance Engine | Flexible recording of student attendance supporting Daily (once a day), Period-wise (per timetable slot), and Session/Batch-wise. | P0 | V2 | Core Architecture | Confirmed | Institute-level global setting determines default attendance mode; attendance records track Present, Absent, Late, Excused, with SMS triggers. |
| **REQ-ACA-005** | Attendance Override Hierarchy | Inheritance and override rules for attendance policies across Institute, Branch, Course, and Class levels. | P2 | V3 | Non-Negotiable Rule 5.C | Proposed (V1-V2 Institute-only) | V2 enforces institute-wide attendance rules; branch/course level overrides deferred to V3 after user approval. |
| **REQ-ACA-006** | Timetable & Scheduling | Timetable generation and conflict detection for classes, rooms, and faculty across recurring weekly schedules. | P1 | V3 | Core Architecture | Confirmed | Timetable detects faculty double-booking and room allocation collisions; displays interactive calendar views for teachers and students. |
| **REQ-ACA-007** | Examinations & Grading | Exam scheduling, question banks, marks entry, grading scales (percentage, GPA, letter grades), and automated ranking calculation. | P1 | V3 | Core Architecture | Confirmed | Supports term exams and unit tests; marks entry includes validation ranges; prevents marks entry after formal exam lock date. |
| **REQ-ACA-008** | Report Card Generation | Automated generation of printable and downloadable PDF report cards featuring institute branding, grading tables, and remarks. | P1 | V3 | Core Architecture | Confirmed | High-performance PDF generation engine renders customizable report cards with QR-code verification. |
| **REQ-ACA-009** | Homework & Assignments | Creation, distribution, submission, grading, and feedback for student homework, including digital file attachments. | P2 | V3 | Core Architecture | Confirmed | Teachers can upload assignments with due dates; students/parents upload submissions; teachers grade and return feedback. |
| **REQ-ACA-010** | Library & Resource Tracking | Cataloging books, issue/return workflows, fine calculation, barcode scanning, and inventory status tracking. | P2 | Deferred (Post-V5) | Core Architecture | Deferred | Basic inventory/library tracking deferred beyond core V5 release to maintain focus on academic and financial core. |
| **REQ-ACA-011** | Transport & Fleet Tracking | Route definition, vehicle management, driver allocation, and student-to-route assignment. | P2 | Deferred (Post-V5) | Core Architecture | Deferred | Transport and live GPS tracking deferred to post-V5 enterprise release. |

---

### D. Finance & Accounting (FIN)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-FIN-001** | Fee Structure & Schedules | Definition of flexible fee plans, recurring installments, component breakdowns (Tuition, Lab, Admission), discounts, and scholarships. | P0 | V2 | Core Architecture | Confirmed | Assigns customized or batch fee plans to students; calculates net payable after approved scholarships/concessions. |
| **REQ-FIN-002** | Multi-Channel Payment Recording | Collection and recording of payments via Cash, UPI, Cheque, Bank Transfer (NEFT/RTGS), and Online Gateways. | P0 | V2 | Core Architecture | Confirmed | Cash/Cheque payments record cashier metadata; cheque collections track clearance status (Pending -> Cleared -> Bounced). |
| **REQ-FIN-003** | Server-Side Payment Gateway Verification | Trustless online payment capture utilizing verified webhook signatures and server-to-server gateway status polling. | P0 | V2 (Manual) / V4 (Integrated) | Core Architecture | Confirmed | **Client-reported payment status is never trusted**; payment is marked `COMPLETED` only upon HMAC-SHA256 signature verification of webhook. |
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
| **REQ-COM-002** | BYO Provider Credentials | Institute-level configuration enabling tenants to plug in their own SMS (DLT-compliant) and WhatsApp Business API credentials. | P1 | V3 | Core Architecture | Confirmed | Institutes can enter their own Twilio/Gupshup/AWS SNS API keys; platform securely encrypts credentials using AES-256-GCM. |
| **REQ-COM-003** | Indian DLT SMS Compliance | Template management supporting Principal Entity (PE) ID, Header ID, and Template Registration IDs mandated by TRAI in India. | P1 | V3 | Core Architecture | Confirmed | SMS dispatch validates DLT template ID and dynamic variable bounds prior to submission to telecom gateways. |
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
| **REQ-MOB-001** | Unified Cross-Platform Mobile App | Dedicated React Native / Expo mobile application for Android and iOS serving students, parents, and teachers. | P1 | V4 | Core Architecture | Confirmed | App provides biometric login, push notifications, offline timetable/attendance caching, and mobile fee payments. |
| **REQ-MOB-002** | Offline Data Caching & Conflict Resolution | Local mobile database (WatermelonDB / SQLite) enabling teachers to take attendance in low-connectivity areas with sync queue. | P1 | V4 | Non-Negotiable Rule 5.F | Confirmed | Offline attendance syncs automatically upon network reconnection; conflicts resolved using server-authoritative timestamping. |
| **REQ-MOB-003** | Offline Payment Prohibition | Strict architectural invariant: payments recorded while offline are **never** treated as confirmed until verified by server. | P0 | V4 | Non-Negotiable Rule 5.F | Confirmed | Mobile clients cannot generate official payment receipts or mark fees cleared while in an offline/unauthenticated state. |
| **REQ-MOB-004** | Dedicated Branded App Publishing | Feasibility assessment and workflow for publishing dedicated, individually branded apps in Google Play & Apple App Store. | P2 | V4 (Feasibility) / Post-V5 | Core Architecture | Proposed / Deferred | Evaluated in Feasibility Audit; individual app store publishing requires separate client developer accounts and is deferred to Enterprise add-on. |

---

### G. Platform-Wide Capabilities (PLT)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-PLT-001** | Multi-Lingual Localization (i18n) | Platform UI localization supporting English, Hindi, and Marathi, with an extensible dictionary framework for additional languages. | P1 | V1 (Framework) / V3 (Complete) | Core Architecture | Confirmed | Users can switch languages dynamically; dates, numbers, and currencies format according to Indian locales (`en-IN`, `hi-IN`, `mr-IN`). |
| **REQ-PLT-002** | Accessibility Compliance (WCAG 2.2 AA) | User interface adherence to WCAG 2.2 Level AA accessibility guidelines across dashboards, forms, and contrast ratios. | P1 | V1 (Baseline) / V5 (Audit) | Core Architecture | Confirmed | Keyboard navigation, screen-reader semantic HTML, focus traps in modals, and color contrast ratios exceeding 4.5:1 verified by automated audits. |
| **REQ-PLT-003** | Global Search Engine | Unified search bar across students, staff, batches, invoices, and academic courses with branch-aware permission scoping. | P2 | V3 | Core Architecture | Confirmed | Search returns sub-second results; never leaks search hits for entities in branches or institutes the user has no permission to access. |
| **REQ-PLT-004** | Bulk CSV / Excel Import Engine | High-throughput data import engine with column mapping, schema validation, preview mode, duplicate detection, and error logging. | P1 | V2 | Core Architecture | Confirmed | Administrators can import hundreds of student/fee records; system flags invalid emails/phone numbers and outputs an error reconciliation sheet. |
| **REQ-PLT-005** | Secure Document Object Storage | Storage architecture separating file metadata in PostgreSQL from actual encrypted files stored in private S3/Supabase Storage. | P0 | V1 | Core Architecture | Confirmed | Files are stored in private buckets; direct public access is blocked; downloads require short-lived (15 min) pre-signed URLs. |
| **REQ-PLT-006** | AI Assistance Engine | Optional AI assistants for automated syllabus drafting, enquiry chatbot, report remarks, and support ticketing. | P2 | V4 | Core Architecture | Confirmed | AI calls pass through a PII-scrubbing filter; institutes can configure their own OpenAI/Gemini keys; strict monthly token spending caps enforced. |
| **REQ-PLT-007** | Public REST API & Webhooks | Versioned external API (`/api/v1`) with scoped API keys (`inst_live_...`), rate limits, and outbound webhook dispatch. | P1 | V4 | Core Architecture | Confirmed | Third-party developers can query authorized endpoints; outbound webhooks sign payloads with HMAC-SHA256 for integrity verification. |

---

### H. Security, Governance & Reliability (SEC)

| Req ID | Module / Area | Description | Priority | Target Version | Source / Traceability | Status | Acceptance Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **REQ-SEC-001** | PostgreSQL Row-Level Security (RLS) | Comprehensive database-level RLS policies enforcing tenant and branch isolation for all reads, inserts, updates, and deletes. | P0 | V1 | Non-Negotiable Rule 4 | Confirmed | Zero data leakage between institutes; queries executed without valid JWT or matching tenant context return 0 rows. |
| **REQ-SEC-002** | Immutable Audit Logging | Tamper-proof audit logging of all sensitive administrative, academic, and financial operations. | P0 | V1 (Baseline) / V5 (Hardened) | Non-Negotiable Rule 5.H | Confirmed | Audit log captures `timestamp`, `institute_id`, `user_id`, `action`, `resource`, `ip_address`, `old_values`, `new_values`; log cannot be mutated or deleted. |
| **REQ-SEC-003** | DPDP Act 2023 & GDPR Privacy Compliance | Data fiduciary compliance workflows: Right to Access, Correction, Erasure, and Minor Guardian Consent management. | P1 | V5 | Non-Negotiable Rule 5.H | Confirmed | Platform supports automated generation of a student's personal data file and anonymization workflows for deleted records. |
| **REQ-SEC-004** | Legal Holds & Data Retention | Ability to place a legal hold on an institute or student account, suspending automatic record archival and deletion routines. | P1 | V5 | Non-Negotiable Rule 5.H | Confirmed | Records flagged under `legal_hold` cannot be purged by retention scripts until hold is formally removed by authorized legal role. |
| **REQ-SEC-005** | Automated Backup & Point-in-Time Recovery | Daily automated encrypted backups with Point-in-Time Recovery (PITR) to meet strict RTO (< 4 hrs) and RPO (< 1 hr) objectives. | P0 | V1 (Strategy) / V5 (Verified) | Non-Negotiable Rule 5.H | Confirmed | Production database supports continuous WAL archiving; automated recovery drills verify restoration within target RTO/RPO windows. |
| **REQ-SEC-006** | Zero Silent Deletion Guarantee | Systematic architectural barrier preventing automated or silent deletion of institute data upon subscription cancellation or payment failure. | P0 | V1 | Non-Negotiable Rule 5.A | Confirmed | Database schemas reject cascade deletes on root institute entities; offboarding requires a formal, multi-factor authenticated decommission workflow. |
| **REQ-SEC-007** | Comprehensive Negative Test Suite | Automated test suite verifying that cross-tenant injection, branch traversal, and unauthorized role elevation fail systematically. | P0 | V1 | Non-Negotiable Rule 2 & 4 | Confirmed | Automated CI pipeline executes 100+ negative security tests; build fails if any test retrieves or modifies foreign tenant data. |

---

## 4. Unrecovered Questions & Assumptions Registry

Because the local workspace lacks historical transcripts of exploratory Questions 1–100, the following assumptions have been formalized as **Unresolved Architectural Questions** and flagged for explicit user review:

1. **Payment Gateway Provider Selection:** Whether Razorpay (India-centric UPI/NetBanking) or Stripe (International/Card) is the primary default gateway for V2–V4. (Assumed: Modular gateway adapter with Razorpay prioritized for Indian market).
2. **Attendance Policy Override Scope:** Whether attendance rules should be strictly Institute-wide (confirmed for V2) or customizable per Branch/Course/Class in V3. (Assumed: Institute-wide in V2, Branch override evaluated in V3).
3. **Biometric Hardware Connectivity:** Whether biometric fingerprint/facial recognition attendance devices require direct local LAN push or cloud API polling. (Assumed: Cloud webhook/API ingestion in V3; proprietary desktop LAN agents deferred).
4. **Branded Mobile App Distribution:** Whether institutes expect dedicated white-label listings in Google Play / Apple App Store under their own organization accounts, or a single unified "InstituteOS" multi-tenant app with tenant code/subdomain login. (Assumed: Single unified multi-tenant app in V4; custom standalone store submissions deferred as an enterprise add-on due to Apple/Google licensing policies).
5. **Double-Entry Financial Strictness:** Whether coaching classes need full formal double-entry general ledgers immediately or simplified single-entry cashbooks in V2, upgrading to double-entry in V5. (Assumed: V2 uses simplified operational fee receipts and dues; formal double-entry General Ledger is scheduled for V5).

---

## 5. Architectural Compliance & Sign-Off

This document constitutes the functional foundation for InstituteOS. All downstream architectural specifications (`FIVE_VERSION_ROADMAP.md`, `SYSTEM_ARCHITECTURE.md`, `DATABASE_DESIGN.md`, `AUTHORIZATION_AND_RLS.md`) strictly derive their boundaries and validations from this master specification.
