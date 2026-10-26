# InstituteOS — Authorization, Access Control & Row-Level Security (RLS)

**Document Version:** 1.0.0  
**Status:** Approved Architectural Specification  
**Security Standard:** Zero-Trust Multi-Tenant Policy-Based Access Control (PBAC)  
**Database Security Layer:** PostgreSQL Row-Level Security (RLS) via Supabase Auth  

---

## 1. Multi-Tenant Authorization Principles

InstituteOS implements a defense-in-depth authorization model combining **Application-Layer Role-Based Access Control (RBAC)** with **Database-Layer Row-Level Security (RLS)**.

### Non-Negotiable Security Invariants
1. **Never Trust Frontend Tenant Context:** The frontend client can never pass `institute_id` or `branch_id` in request payloads to claim authorization. Tenant identity is extracted strictly from the cryptographically verified JWT issued by the server.
2. **Database as the Ultimate Boundary:** Even if an application bug, injection flaw, or rogue API route executes an un-scoped query (e.g. `SELECT * FROM students`), the PostgreSQL RLS engine restricts the query results exclusively to the caller's authorized tenant.
3. **No Unauthenticated Public Bypasses:** Public endpoints (e.g. inquiry forms) run through isolated, rate-limited public schemas with strict insert-only constraints, completely isolated from administrative tables.
4. **Service-Role Key Quarantine:** The Supabase `service_role` key (which bypasses RLS) is strictly prohibited in web client code and routine server actions. It is quarantined exclusively to background job workers and administrative migration scripts, with mandatory explicit tenant filtering.

---

## 2. Institutional Role Hierarchy & Scope Definitions

InstituteOS defines seven distinct institutional roles. Every role operates within an explicit organizational scope:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ROLE HIERARCHY & SCOPES                         │
├───────────────────┬──────────────────┬─────────────────────────────────┤
│ ROLE              │ SCOPE LEVEL      │ PRIMARY RESPONSIBILITIES        │
├───────────────────┼──────────────────┼─────────────────────────────────┤
│ Platform Super    │ Global Platform  │ SaaS administration, tenant     │
│ Admin             │ (All Institutes) │ provisioning, billing oversight │
├───────────────────┼──────────────────┼─────────────────────────────────┤
│ Institute Owner   │ Full Institute   │ Legal ownership, billing, full  │
│                   │ (All Branches)   │ operational/financial authority │
├───────────────────┼──────────────────┼─────────────────────────────────┤
│ Institute Admin   │ Full Institute   │ Academic configurations, staff  │
│                   │ (All Branches)   │ onboarding, master timetables   │
├───────────────────┼──────────────────┼─────────────────────────────────┤
│ Branch Manager    │ Assigned Branch  │ Branch daily operations, staff  │
│                   │ (Single/Multi)   │ attendance, local admissions    │
├───────────────────┼──────────────────┼─────────────────────────────────┤
│ Teacher / Faculty │ Assigned Branch  │ Class attendance, homework,     │
│                   │ & Classes        │ marks entry, student remarks    │
├───────────────────┼──────────────────┼─────────────────────────────────┤
│ Accountant        │ Assigned Branch  │ Fee collection, receipting,     │
│                   │ or Institute     │ dues tracking, expenses         │
├───────────────────┼──────────────────┼─────────────────────────────────┤
│ Receptionist      │ Assigned Branch  │ Visitor logs, walk-in enquiries,│
│                   │                  │ basic student lookups           │
├───────────────────┼──────────────────┼─────────────────────────────────┤
│ Student / Parent  │ Personal Record  │ View attendance, timetable, fee │
│ (Shared Identity) │ Only             │ dues, online receipt download   │
└───────────────────┴──────────────────┴─────────────────────────────────┘
```

---

## 3. The Shared Student / Parent Credential Model

### Architectural Design
In accordance with **Non-Negotiable Project Rule 5.B**, InstituteOS utilizes a **single unified login credential per enrolled student**, which is shared directly between the student and their authorized parents/guardians. The platform does not provision separate parent accounts in the initial approved model.

### Explicit Limitations & Security Risks
Deploying a shared credential architecture creates distinct operational and non-repudiation constraints that must be formally recognized:

1. **Inability to Distinguish the Physical Actor:**
   - When an action is logged (e.g., viewing report cards, submitting homework, or acknowledging a disciplinary notice), the system audit trail records the user ID of the student. The system **cannot verify** whether the student or the parent completed the interaction.
2. **Non-Repudiation Vulnerability in Communications:**
   - A student could access the portal and mark a fee reminder or disciplinary notification as "read" without the parent ever seeing it.
   - *Mitigation:* Critical communications (absence alerts, overdue fee demands) are dispatched directly via external out-of-band channels (SMS and WhatsApp) to the verified `guardian_phone` stored on the student profile.
3. **Homework & Academic Integrity:**
   - Digital submissions uploaded through the portal cannot be authenticated as student work versus parent assistance.
4. **Financial Consent on Online Payments:**
   - Any person in possession of the shared student password can initiate online fee payment workflows.
   - *Mitigation:* Payment gateways enforce secondary two-factor authentication (OTP sent to cardholder/UPI mobile number).

---

## 4. JWT Claims & PostgreSQL Session Context

Upon successful authentication, Supabase Auth embeds custom claims in the signed JWT `app_metadata` object:

```json
{
  "sub": "4a7375a0-9c2f-4882-990a-5b12854b7c12",
  "email": "sarah.admin@apexacademy.edu.in",
  "app_metadata": {
    "institute_id": "8f1a23c0-32b1-4f81-8172-e19034cb9911",
    "system_role": "BRANCH_MANAGER",
    "assigned_branches": [
      "22e84120-77a4-4903-8d2a-194567ac8833"
    ],
    "is_super_admin": false
  }
}
```

### PostgreSQL Helper Functions
These lightweight, immutable SQL helper functions execute within PostgreSQL session state to extract tenant claims with zero overhead:

```sql
-- Extract authenticated User ID
CREATE OR REPLACE FUNCTION auth_uid() RETURNS UUID AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb ->> 'sub', '')::UUID;
$$ LANGUAGE sql STABLE;

-- Extract active Tenant Institute ID
CREATE OR REPLACE FUNCTION current_institute_id() RETURNS UUID AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'institute_id', '')::UUID;
$$ LANGUAGE sql STABLE;

-- Extract User Institutional Role
CREATE OR REPLACE FUNCTION current_user_role() RETURNS VARCHAR AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'system_role', '');
$$ LANGUAGE sql STABLE;

-- Check if User has Branch Access (supports Institute Owner/Admin all-branch bypass)
CREATE OR REPLACE FUNCTION has_branch_access(target_branch_id UUID) RETURNS BOOLEAN AS $$
DECLARE
    v_role VARCHAR;
    v_branches JSONB;
BEGIN
    v_role := current_user_role();
    
    -- Institute Owners and Admins have global access across all institute branches
    IF v_role IN ('OWNER', 'ADMIN') THEN
        RETURN true;
    END IF;

    -- If the resource is institute-wide (no branch assigned), allow
    IF target_branch_id IS NULL THEN
        RETURN true;
    END IF;

    -- Extract assigned branch UUID array from JWT claims
    v_branches := current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' -> 'assigned_branches';
    
    RETURN v_branches ? target_branch_id::text;
END;
$$ LANGUAGE plpgsql STABLE;
```

---

## 5. Comprehensive RLS Policy Implementations

### A. RLS for `student_profiles`
Students may only read their own profile; branch managers and staff can read students in their assigned branches; only Admins/Owners/Branch Managers can insert/update.
```sql
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;

-- SELECT POLICY
CREATE POLICY policy_student_profiles_select ON student_profiles
FOR SELECT USING (
    institute_id = current_institute_id()
    AND (
        -- Students see only their own record
        (current_user_role() = 'STUDENT' AND institute_user_id IN (
            SELECT id FROM institute_users WHERE user_id = auth_uid()
        ))
        -- Staff see students enrolled in their assigned branches
        OR (current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'TEACHER', 'ACCOUNTANT', 'RECEPTIONIST')
            AND id IN (
                SELECT student_profile_id FROM student_enrollments 
                WHERE has_branch_access(branch_id)
            ))
    )
);

-- INSERT / UPDATE POLICY
CREATE POLICY policy_student_profiles_modify ON student_profiles
FOR ALL USING (
    institute_id = current_institute_id()
    AND current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER')
)
WITH CHECK (
    institute_id = current_institute_id()
    AND current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER')
);
```

### B. RLS for `attendance_records`
Teachers can view and record attendance only for their assigned branches and assigned classes.
```sql
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- SELECT POLICY
CREATE POLICY policy_attendance_select ON attendance_records
FOR SELECT USING (
    institute_id = current_institute_id()
    AND (
        -- Students see only their personal attendance
        (current_user_role() = 'STUDENT' AND student_enrollment_id IN (
            SELECT se.id FROM student_enrollments se
            JOIN student_profiles sp ON se.student_profile_id = sp.id
            JOIN institute_users iu ON sp.institute_user_id = iu.id
            WHERE iu.user_id = auth_uid()
        ))
        -- Staff see attendance within assigned branch
        OR (current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'TEACHER', 'RECEPTIONIST')
            AND has_branch_access(branch_id))
    )
);

-- INSERT POLICY (Recording Attendance)
CREATE POLICY policy_attendance_insert ON attendance_records
FOR INSERT WITH CHECK (
    institute_id = current_institute_id()
    AND has_branch_access(branch_id)
    AND current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'TEACHER')
);

-- UPDATE POLICY (Restricted to Admins and Branch Managers within 7 days)
CREATE POLICY policy_attendance_update ON attendance_records
FOR UPDATE USING (
    institute_id = current_institute_id()
    AND has_branch_access(branch_id)
    AND current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER')
    AND attendance_date >= (CURRENT_DATE - INTERVAL '7 days')
);
```

### C. RLS for `payments` and `invoices`
Strict segregation: Teachers and Receptionists have zero access to financial ledgers. Accountants and Branch Managers are scoped to their branches.
```sql
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- SELECT POLICY
CREATE POLICY policy_payments_select ON payments
FOR SELECT USING (
    institute_id = current_institute_id()
    AND (
        -- Student can only see their own receipts
        (current_user_role() = 'STUDENT' AND invoice_id IN (
            SELECT inv.id FROM invoices inv
            JOIN student_fee_plans sfp ON inv.student_fee_plan_id = sfp.id
            JOIN student_enrollments se ON sfp.student_enrollment_id = se.id
            JOIN student_profiles sp ON se.student_profile_id = sp.id
            JOIN institute_users iu ON sp.institute_user_id = iu.id
            WHERE iu.user_id = auth_uid()
        ))
        -- Financial staff see payments for assigned branches
        OR (current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'ACCOUNTANT')
            AND has_branch_access(branch_id))
    )
);

-- INSERT POLICY (Recording Collections)
CREATE POLICY policy_payments_insert ON payments
FOR INSERT WITH CHECK (
    institute_id = current_institute_id()
    AND has_branch_access(branch_id)
    AND current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'ACCOUNTANT')
);

-- UPDATE and DELETE: Strictly prohibited for all roles via policy
CREATE POLICY policy_payments_immutable ON payments
FOR UPDATE USING (false);
```

---

## 6. Privileged Access & Service-Role Isolation

| Context | Access Mechanism | RLS Bypass? | Security Controls & Isolation Invariants |
| :--- | :--- | :--- | :--- |
| **Standard User Web Session** | Supabase User JWT | No | Bound directly to user session claims via RLS. |
| **Mobile App Client** | Refreshable Bearer JWT | No | Exactly matches web session RLS boundaries. |
| **Platform Super Admin** | Supabase User JWT (`is_super_admin: true`) | Conditional | Accesses platform tables directly; tenant data inspection requires explicit audit logging reason. |
| **Background Queue Worker** | `SUPABASE_SERVICE_ROLE_KEY` | **Yes** | Worker code **must** explicitly inject `WHERE institute_id = target_id` in all SQL statements. Code review rejects un-scoped queries. |
| **External Partner API** | Scoped API Key (`inst_live_...`) | No | API middleware verifies key, queries tenant ID, and sets PostgreSQL session variables via `SET LOCAL`. |

---

## 7. Negative Security Test Matrix

Automated CI/CD security pipelines execute negative test suites asserting zero data leakage:

| Test ID | Attacker Role / Context | Target Resource | Action Attempted | Expected System Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **NEG-SEC-001** | Student (Institute A) | Institute B Student Records | `SELECT * FROM student_profiles WHERE institute_id = 'inst_B'` | Returns **0 rows**. Database RLS filters all rows silently. |
| **NEG-SEC-002** | Student (Institute A) | Institute A Other Student Profiles | `SELECT * FROM student_profiles WHERE id = 'other_student_id'` | Returns **0 rows**. Filtered by `auth_uid()` sub-query. |
| **NEG-SEC-003** | Teacher (Branch 1) | Branch 2 Attendance Records | `SELECT * FROM attendance_records WHERE branch_id = 'branch_2'` | Returns **0 rows**. Blocked by `has_branch_access()`. |
| **NEG-SEC-004** | Teacher | Payments Table | `SELECT * FROM payments` | Returns **0 rows**. Role `TEACHER` has no select grant on `payments`. |
| **NEG-SEC-005** | Accountant | Attendance Records | `INSERT INTO attendance_records ...` | Throws `42501 permission_denied`. Accountants cannot mark attendance. |
| **NEG-SEC-006** | Institute Admin | Completed Payment Receipt | `DELETE FROM payments WHERE id = 'receipt_123'` | Throws `permission_denied` via `policy_payments_immutable`. |
| **NEG-SEC-007** | Attacker with stolen JWT | Tampered Tenant Header | HTTP request with `X-Tenant-Slug: victim` | Middleware rejects: JWT `institute_id` does not match domain slug. |
| **NEG-SEC-008** | Unauthenticated Public | Internal Student API | `GET /api/v1/students` | Returns `401 Unauthorized`. |
