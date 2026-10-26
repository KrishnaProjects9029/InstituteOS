# InstituteOS — Version 1 (Core Foundation) Detailed Execution Specification

**Document Version:** 1.0.0  
**Target Version:** V1 — Core Foundation & Multi-Tenant Infrastructure  
**Status:** Pre-Implementation Specification (Pending User Sign-Off)  
**Governance Invariant:** No production code, package installation, or database modification before formal approval.  

---

## 1. V1 Execution Scope & Objectives

The primary objective of Version 1 is to establish a secure, verified, and testable multi-tenant core upon which all subsequent academic, financial, and operational modules will build.

### In Scope for V1:
1. **Multi-Tenant Database Foundation:** Forward-only SQL migrations creating root tenant tables (`institutes`, `branches`, `users`, `institute_users`, `user_branch_assignments`, `audit_logs`).
2. **Row-Level Security (RLS) Engine:** 100% coverage on tenant tables; session context evaluation via JWT `app_metadata` (`institute_id`, `branch_id`, `system_role`).
3. **Authentication & Identity:** Supabase Auth integration (email/password, password reset, session refresh, and instant session invalidation).
4. **Application Framework & Shell UI:** Next.js 15+ App Router, TypeScript (strict), Tailwind CSS, accessible shadcn/ui components, and multi-tenant URL routing (`/[tenantSlug]/dashboard`).
5. **Immutable Audit Logging:** Database-level trigger preventing modification or deletion of audit records.
6. **Automated Testing & Security CI:** Automated test suite (Unit, pgTAP RLS isolation, Playwright E2E) with synthetic multi-tenant test fixtures.

### Explicitly Excluded from V1:
- Admissions, student profiles, and parent workflows (Scheduled for V2).
- Fee collections, invoices, and accounting (Scheduled for V2 & V5).
- Timetables, exams, and attendance recording (Scheduled for V2 & V3).
- SMS, WhatsApp, and email notification workers (Scheduled for V3).
- Custom domains, website builder, and mobile apps (Scheduled for V4).

---

## 2. Target Project File Structure for V1

When V1 implementation begins, the repository structure will adhere strictly to the following modular monolith layout:

```
InstituteOS/
├── .github/
│   └── workflows/
│       ├── ci.yml                     # Lint, typecheck, unit tests, RLS tests
│       └── security-scan.yml          # Dependency audit & secret detection
├── docs/
│   └── planning/                      # Master Architecture & Planning Docs (12 files)
├── supabase/
│   ├── migrations/
│   │   ├── 20261026000001_create_tenants_and_branches.sql
│   │   ├── 20261026000002_create_users_and_iam.sql
│   │   ├── 20261026000003_create_audit_logs.sql
│   │   └── 20261026000004_enable_rls_and_policies.sql
│   ├── tests/
│   │   └── rls_isolation_test.sql     # pgTAP cross-tenant negative test assertions
│   └── seed.sql                       # Synthetic test institutes (Alpha & Beta)
├── src/
│   ├── app/
│   │   ├── (auth)/
│   │   │   ├── login/page.tsx
│   │   │   ├── forgot-password/page.tsx
│   │   │   └── reset-password/page.tsx
│   │   ├── (dashboard)/
│   │   │   └── [tenantSlug]/
│   │   │       ├── layout.tsx         # Tenant shell layout (sidebar, header, nav)
│   │   │       ├── page.tsx           # Default dashboard overview
│   │   │       ├── branches/page.tsx  # Branch management
│   │   │       └── settings/page.tsx  # Institute profile & configurations
│   │   ├── api/
│   │   │   ├── health/route.ts        # System liveness & readiness check
│   │   │   └── v1/auth/callback/route.ts
│   │   ├── layout.tsx                 # Root layout with Theme & i18n providers
│   │   └── page.tsx                   # Platform landing / redirect to login
│   ├── middleware.ts                  # Subdomain / path-based tenant context resolution
│   ├── modules/
│   │   ├── tenant/
│   │   │   ├── services/tenant.service.ts
│   │   │   └── schemas/tenant.schema.ts
│   │   ├── iam/
│   │   │   ├── services/auth.service.ts
│   │   │   ├── guards/rbac.guard.ts
│   │   │   └── types/roles.ts
│   │   └── audit/
│   │       └── services/audit.service.ts
│   └── shared/
│       ├── db/
│       │   ├── supabase-client.ts     # Client-side Supabase client (anon key)
│       │   ├── supabase-server.ts     # Server component Supabase client (cookies)
│       │   └── supabase-admin.ts      # Service-role client (quarantined)
│       ├── ui/                        # shadcn/ui accessible components
│       └── i18n/                      # Translation dictionaries (en, hi, mr)
├── tests/
│   ├── unit/                          # Business logic & validation tests (Vitest)
│   └── e2e/                           # Browser journeys & security checks (Playwright)
├── package.json
├── tsconfig.json
├── tailwind.config.ts
└── next.config.ts
```

---

## 3. Step-by-Step V1 Implementation Roadmap

The execution of V1 is broken into six distinct, verifiable phases:

### Phase 1: Project Scaffolding & Toolchain Setup
- Initialize Next.js 15+ project with strict TypeScript (`strict: true`, `noImplicitAny: true`).
- Configure Tailwind CSS with accessible color contrast tokens.
- Install shadcn/ui primitives (Radix UI) and lucide-react icons.
- Configure ESLint, Prettier, and Husky pre-commit hooks.
- Verification Gate: `npm run lint` and `npm run build` pass with zero warnings.

### Phase 2: Database Schema & Migration Scripts
- Initialize Supabase project configuration (`supabase/config.toml`).
- Create forward-only SQL migration `20261026000001_create_tenants_and_branches.sql` (`institutes`, `branches`).
- Create forward-only SQL migration `20261026000002_create_users_and_iam.sql` (`users`, `institute_users`, `user_branch_assignments`).
- Create forward-only SQL migration `20261026000003_create_audit_logs.sql` with immutability triggers.
- Create composite indexes on all tables prefixed with `institute_id`.
- Verification Gate: `supabase db reset` applies all migrations cleanly with zero errors.

### Phase 3: PostgreSQL Row-Level Security (RLS) Implementation
- Create session helper functions (`current_institute_id()`, `current_user_role()`, `has_branch_access()`).
- Enable RLS on 100% of tenant tables.
- Define explicit `SELECT`, `INSERT`, `UPDATE`, and `DELETE` policies for each table.
- Create pgTAP test suite (`supabase/tests/rls_isolation_test.sql`) asserting:
  - Tenant A cannot read or write Tenant B records.
  - Branch Manager cannot access unassigned branches.
  - Audit log table strictly rejects `UPDATE` and `DELETE` statements.
- Verification Gate: `supabase test db` passes 100% of assertions.

### Phase 4: Authentication, Middleware & Tenant Resolution
- Implement Supabase Auth SSR helper in `src/shared/db/supabase-server.ts`.
- Implement Next.js edge middleware (`src/middleware.ts`) to extract tenant context from hostname or route slug.
- Build login, password recovery, and session invalidation flows.
- Implement RBAC permission guard (`rbac.guard.ts`) verifying role permissions server-side.
- Verification Gate: Authenticated session injects valid JWT claims; unauthorized routes redirect to login.

### Phase 5: Accessible Dashboard Shell UI
- Create responsive dashboard layout with collapsible sidebar, branch selector dropdown, and user profile menu.
- Implement breadcrumbs, accessible modal dialogs, and toast notifications.
- Add locale switcher skeleton supporting English (`en`), Hindi (`hi`), and Marathi (`mr`).
- Verification Gate: Automated Axe accessibility audit verifies WCAG 2.2 AA compliance score > 95%.

### Phase 6: Automated CI/CD & Synthetic Test Harness
- Configure GitHub Actions CI workflow (`.github/workflows/ci.yml`).
- Create synthetic seed generator (`supabase/seed.sql`) populating two complete test institutes (`Alpha Institute` and `Beta Academy`).
- Create Playwright E2E smoke tests for multi-tenant login and negative cross-tenant isolation.
- Verification Gate: Complete CI pipeline runs and passes green in under 5 minutes.

---

## 4. V1 Acceptance Sign-Off Matrix

Before Version 2 can be unlocked, the following audit checklist must be signed off:

| Pillar | Requirement | Verification Standard | Sign-Off Status |
| :--- | :--- | :--- | :--- |
| **Tenant Isolation** | PostgreSQL RLS on all tables | 0 leakage in pgTAP negative tests | Pending V1 Execution |
| **Authentication** | Supabase Auth with custom claims | Session invalidation revokes tokens | Pending V1 Execution |
| **Immutability** | Audit log triggers active | SQL UPDATE/DELETE throws exception | Pending V1 Execution |
| **Accessibility** | UI Shell adheres to WCAG 2.2 AA | Axe Core score > 95% | Pending V1 Execution |
| **CI/CD** | Automated pipeline active | 100% test pass rate on PRs | Pending V1 Execution |
