-- =============================================================================
-- Migration: 20261026000006_repair_branch_authorization_and_rls.sql
-- Description: Repairs branch scoping in user_branch_assignments RLS,
--              enforces FORCE ROW LEVEL SECURITY on all tenant tables,
--              adds statement-level BEFORE TRUNCATE trigger on audit_logs,
--              sets triggers to ENABLE ALWAYS, and secures search_path on helpers.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Secure Session Claim Helper Functions (Search Path Hardening)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION auth_uid() 
RETURNS UUID 
LANGUAGE sql 
STABLE
SET search_path = public
AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb ->> 'sub', '')::UUID;
$$;

CREATE OR REPLACE FUNCTION current_institute_id() 
RETURNS UUID 
LANGUAGE sql 
STABLE
SET search_path = public
AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'institute_id', '')::UUID;
$$;

CREATE OR REPLACE FUNCTION current_user_role() 
RETURNS VARCHAR 
LANGUAGE sql 
STABLE
SET search_path = public
AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'system_role', '');
$$;

CREATE OR REPLACE FUNCTION is_platform_super_admin() 
RETURNS BOOLEAN 
LANGUAGE sql 
STABLE
SET search_path = public
AS $$
    SELECT COALESCE((current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'is_super_admin')::BOOLEAN, false);
$$;

CREATE OR REPLACE FUNCTION has_branch_access(target_branch_id UUID) 
RETURNS BOOLEAN 
LANGUAGE plpgsql 
STABLE
SET search_path = public
AS $$
DECLARE
    v_role VARCHAR;
    v_branches JSONB;
BEGIN
    -- Super admins bypass branch checks
    IF is_platform_super_admin() THEN
        RETURN true;
    END IF;

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
    
    IF v_branches IS NULL THEN
        RETURN false;
    END IF;

    RETURN v_branches ? target_branch_id::text;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. Repair Branch-Level Authorization for user_branch_assignments
-- -----------------------------------------------------------------------------

-- Drop previous leaky policy
DROP POLICY IF EXISTS policy_user_branch_assignments_select ON user_branch_assignments;

-- Create hardened policy: Branch Managers CANNOT view assignments outside their granted branches
CREATE POLICY policy_user_branch_assignments_select ON user_branch_assignments
FOR SELECT USING (
    is_platform_super_admin()
    OR (
        institute_id = current_institute_id()
        AND (
            -- Users can see their own assignment
            institute_user_id IN (SELECT id FROM institute_users WHERE user_id = auth_uid())
            -- Owners and Admins have institute-wide visibility
            OR current_user_role() IN ('OWNER', 'ADMIN')
            -- Branch Managers are strictly scoped to branches they are assigned to
            OR (current_user_role() = 'BRANCH_MANAGER' AND has_branch_access(branch_id))
        )
    )
);

-- -----------------------------------------------------------------------------
-- 3. Harden Audit Logs Immutability (TRUNCATE Guard & ENABLE ALWAYS)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION protect_audit_logs_truncate() 
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RAISE EXCEPTION 'Audit logs are strictly immutable. TRUNCATE operation is prohibited.';
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_logs_truncate ON audit_logs;
CREATE TRIGGER trg_audit_logs_truncate
BEFORE TRUNCATE ON audit_logs
FOR EACH STATEMENT EXECUTE FUNCTION protect_audit_logs_truncate();

-- Ensure row and statement triggers fire even if session_replication_role is replica
ALTER TABLE audit_logs ENABLE ALWAYS TRIGGER trg_audit_logs_immutability;
ALTER TABLE audit_logs ENABLE ALWAYS TRIGGER trg_audit_logs_truncate;

-- -----------------------------------------------------------------------------
-- 4. Apply FORCE ROW LEVEL SECURITY Across All Tenant Tables
-- Note: Applies RLS to table owner accounts. Supabase service_role / superusers
-- still possess BYPASSRLS in PostgreSQL and must be governed at the application layer.
-- -----------------------------------------------------------------------------

ALTER TABLE institutes FORCE ROW LEVEL SECURITY;
ALTER TABLE branches FORCE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;
ALTER TABLE institute_users FORCE ROW LEVEL SECURITY;
ALTER TABLE user_branch_assignments FORCE ROW LEVEL SECURITY;
ALTER TABLE audit_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE courses FORCE ROW LEVEL SECURITY;
ALTER TABLE classes FORCE ROW LEVEL SECURITY;
ALTER TABLE attendance_rules FORCE ROW LEVEL SECURITY;
ALTER TABLE attendance_rule_audit_history FORCE ROW LEVEL SECURITY;
