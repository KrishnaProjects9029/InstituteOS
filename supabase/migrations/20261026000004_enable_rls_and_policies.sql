-- =============================================================================
-- Migration: 20261026000004_enable_rls_and_policies.sql
-- Description: Establishes Row-Level Security policies and JWT session helpers
-- =============================================================================

-- Session Claims Helper Functions
CREATE OR REPLACE FUNCTION auth_uid() RETURNS UUID AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb ->> 'sub', '')::UUID;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION current_institute_id() RETURNS UUID AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'institute_id', '')::UUID;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION current_user_role() RETURNS VARCHAR AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'system_role', '');
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION is_platform_super_admin() RETURNS BOOLEAN AS $$
    SELECT COALESCE((current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'is_super_admin')::BOOLEAN, false);
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION has_branch_access(target_branch_id UUID) RETURNS BOOLEAN AS $$
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
$$ LANGUAGE plpgsql STABLE;

-- -----------------------------------------------------------------------------
-- Enable RLS on Tenant Foundation Tables
-- -----------------------------------------------------------------------------
ALTER TABLE institutes ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE institute_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_branch_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- RLS Policies: institutes
-- -----------------------------------------------------------------------------
CREATE POLICY policy_institutes_select ON institutes
FOR SELECT USING (
    is_platform_super_admin() OR id = current_institute_id()
);

CREATE POLICY policy_institutes_update ON institutes
FOR UPDATE USING (
    is_platform_super_admin() OR (id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
) WITH CHECK (
    is_platform_super_admin() OR (id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
);

-- -----------------------------------------------------------------------------
-- RLS Policies: branches
-- -----------------------------------------------------------------------------
CREATE POLICY policy_branches_select ON branches
FOR SELECT USING (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND has_branch_access(id))
);

CREATE POLICY policy_branches_insert ON branches
FOR INSERT WITH CHECK (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
);

CREATE POLICY policy_branches_update ON branches
FOR UPDATE USING (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
) WITH CHECK (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
);

-- -----------------------------------------------------------------------------
-- RLS Policies: users
-- -----------------------------------------------------------------------------
CREATE POLICY policy_users_select ON users
FOR SELECT USING (
    is_platform_super_admin() 
    OR id = auth_uid()
    OR id IN (
        SELECT user_id FROM institute_users WHERE institute_id = current_institute_id()
    )
);

CREATE POLICY policy_users_update ON users
FOR UPDATE USING (
    is_platform_super_admin() OR id = auth_uid()
) WITH CHECK (
    is_platform_super_admin() OR id = auth_uid()
);

-- -----------------------------------------------------------------------------
-- RLS Policies: institute_users
-- -----------------------------------------------------------------------------
CREATE POLICY policy_institute_users_select ON institute_users
FOR SELECT USING (
    is_platform_super_admin()
    OR (
        institute_id = current_institute_id()
        AND (
            user_id = auth_uid()
            OR current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'ACCOUNTANT', 'RECEPTIONIST')
        )
    )
);

CREATE POLICY policy_institute_users_insert ON institute_users
FOR INSERT WITH CHECK (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
);

CREATE POLICY policy_institute_users_update ON institute_users
FOR UPDATE USING (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
) WITH CHECK (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
);

-- -----------------------------------------------------------------------------
-- RLS Policies: user_branch_assignments
-- -----------------------------------------------------------------------------
CREATE POLICY policy_user_branch_assignments_select ON user_branch_assignments
FOR SELECT USING (
    is_platform_super_admin()
    OR (
        institute_id = current_institute_id()
        AND (
            institute_user_id IN (SELECT id FROM institute_users WHERE user_id = auth_uid())
            OR current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER')
        )
    )
);

CREATE POLICY policy_user_branch_assignments_modify ON user_branch_assignments
FOR ALL USING (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
) WITH CHECK (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
);

-- -----------------------------------------------------------------------------
-- RLS Policies: audit_logs
-- -----------------------------------------------------------------------------
CREATE POLICY policy_audit_logs_select ON audit_logs
FOR SELECT USING (
    is_platform_super_admin() OR (institute_id = current_institute_id() AND current_user_role() IN ('OWNER', 'ADMIN'))
);

CREATE POLICY policy_audit_logs_insert ON audit_logs
FOR INSERT WITH CHECK (
    institute_id = current_institute_id()
);
