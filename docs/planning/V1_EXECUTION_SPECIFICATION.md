# InstituteOS — Version 1 (Core Foundation) Detailed Execution Specification

**Document Version:** 1.1.0 (Remediated Baseline)  
**Target Version:** V1 — Core Foundation & Multi-Tenant Infrastructure  
**Status:** Remediated Specification with Mandatory Attendance-Rule Hierarchy  

---

## 1. V1 Execution Scope & Objectives

The primary objective of Version 1 is to establish a secure, verified, and testable multi-tenant core upon which all subsequent academic, financial, and operational modules will build.

### In Scope for V1:
1. **Multi-Tenant Database Foundation:** Forward-only SQL migrations creating root tenant tables (`institutes`, `branches`, `users`, `institute_users`, `user_branch_assignments`, `audit_logs`).
2. **Attendance-Rule Hierarchical Inheritance Engine:** Full 4-tier inheritance engine:
   $$\text{Institute Default} \longrightarrow \text{Branch Override} \longrightarrow \text{Course Override} \longrightarrow \text{Class Override}$$
   Evaluation precedence: **Class > Course > Branch > Institute**. Includes rule types, validation constraints, audit history, deterministic resolution function, and RLS policies.
3. **Academic Reference Entities:** Coherent baseline `courses` and `classes` tables supporting the attendance inheritance hierarchy.
4. **Row-Level Security (RLS) & Branch Authorization Hardening:** 100% coverage on tenant tables; `FORCE ROW LEVEL SECURITY` applied; `policy_user_branch_assignments_select` restricted so Branch Managers only see assignments in branches they are granted access to.
5. **Hardened Audit Logging:** Database-level `BEFORE UPDATE`, `BEFORE DELETE`, and statement-level `BEFORE TRUNCATE` triggers set to `ENABLE ALWAYS`.
6. **Authentication & Identity:** Supabase Auth integration (email/password, password reset, session refresh, and instant session invalidation).
7. **Application Framework & Shell UI:** Next.js 15+ App Router, TypeScript (strict), Tailwind CSS, accessible shadcn/ui components, and multi-tenant URL routing (`/[tenantSlug]/dashboard`).
8. **Automated Testing & Security CI:** Automated test suite with synthetic multi-tenant test fixtures covering attendance inheritance, branch authorization, and cross-tenant isolation.

---

## 2. Migration Registry for V1

The V1 database architecture is established strictly through forward-only migrations:

```
supabase/migrations/
├── 20261026000001_create_tenants_and_branches.sql       # Institutes & Branches
├── 20261026000002_create_users_and_iam.sql               # Users, Institute Users & Assignments
├── 20261026000003_create_audit_logs.sql                  # Audit Log Foundation
├── 20261026000004_enable_rls_and_policies.sql            # Initial RLS Policies & Session Helpers
├── 20261026000005_create_attendance_rules_hierarchy.sql # [NEW] 4-Tier Attendance Rule Engine
└── 20261026000006_repair_branch_authorization_and_rls.sql# [NEW] Branch Scoping Fix, FORCE RLS & TRUNCATE Guard
```

---

## 3. Approved Strategic Decisions Preserved in V1 Planning

1. **Stripe First:** Formally established in architecture specifications for V4 online fee payments and subscription billing.
2. **Separate Branded Mobile Apps:** Formally established for V4 mobile delivery with automated multi-tenant EAS/Fastlane release pipelines.
3. **Dual SMS Modes:** Formally established for V3 communications (BYO carrier vault + InstituteOS-managed credit pool).
4. **Attendance Inheritance in V1:** Implemented directly in V1 migration `20261026000005`.
