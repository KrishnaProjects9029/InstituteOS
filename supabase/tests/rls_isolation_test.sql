-- =============================================================================
-- Test Suite: supabase/tests/rls_isolation_test.sql
-- Description: Comprehensive pgTAP verification suite testing:
--              1. Table & function schema existence
--              2. Audit log immutability (UPDATE, DELETE, TRUNCATE protection)
--              3. Attendance-rule validation constraints & cross-tenant rejection
--              4. Attendance-rule hierarchy resolution & precedence (Class > Course > Branch > Inst)
--              5. Inactive rule fallback behavior
--              6. Cross-tenant isolation via RLS policies
--              7. Branch Manager scoping and unassigned branch restrictions
--              8. Ordinary user (least privilege) restrictions
--              9. Platform super admin privileged access
-- =============================================================================

BEGIN;
SELECT plan(40);

-- Ensure authenticated role has standard schema grants so tests evaluate RLS policies
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- -----------------------------------------------------------------------------
-- Helper Function: Set JWT Claims for RLS Impersonation Testing
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_test_claims(
    p_user_id UUID,
    p_institute_id UUID,
    p_system_role VARCHAR,
    p_assigned_branches UUID[] DEFAULT '{}'::UUID[],
    p_is_super_admin BOOLEAN DEFAULT false
) RETURNS void AS $$
DECLARE
    v_branches_json JSONB;
BEGIN
    SELECT COALESCE(jsonb_agg(b::text), '[]'::jsonb) INTO v_branches_json FROM unnest(p_assigned_branches) b;

    PERFORM set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub', p_user_id,
            'role', 'authenticated',
            'app_metadata', jsonb_build_object(
                'institute_id', p_institute_id,
                'system_role', p_system_role,
                'is_super_admin', p_is_super_admin,
                'assigned_branches', v_branches_json
            )
        )::text,
        true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- 1. Table & Function Schema Verification (16 tests)
-- -----------------------------------------------------------------------------
SELECT has_table('institutes', 'institutes table exists');
SELECT has_table('branches', 'branches table exists');
SELECT has_table('users', 'users table exists');
SELECT has_table('institute_users', 'institute_users table exists');
SELECT has_table('user_branch_assignments', 'user_branch_assignments table exists');
SELECT has_table('courses', 'courses table exists');
SELECT has_table('classes', 'classes table exists');
SELECT has_table('attendance_rules', 'attendance_rules table exists');
SELECT has_table('attendance_rule_audit_history', 'attendance_rule_audit_history table exists');
SELECT has_table('audit_logs', 'audit_logs table exists');

SELECT has_function('auth_uid', 'auth_uid helper exists');
SELECT has_function('current_institute_id', 'current_institute_id helper exists');
SELECT has_function('current_user_role', 'current_user_role helper exists');
SELECT has_function('is_platform_super_admin', 'is_platform_super_admin helper exists');
SELECT has_function('has_branch_access', 'has_branch_access helper exists');
SELECT has_function('resolve_effective_attendance_rule', 'resolve_effective_attendance_rule function exists');

-- -----------------------------------------------------------------------------
-- 2. Audit Log Immutability Protection (3 tests)
-- -----------------------------------------------------------------------------

-- Insert a baseline record into audit_logs so UPDATE and DELETE triggers have a row to intercept
INSERT INTO audit_logs (id, institute_id, action, entity_name, entity_id)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    'INITIAL_RECORD',
    'institutes',
    '11111111-1111-1111-1111-111111111111'
);

SELECT throws_ok(
    $$UPDATE audit_logs SET action = 'TAMPERED' WHERE id = '00000000-0000-0000-0000-000000000001'$$,
    'Audit logs are strictly immutable. UPDATE and DELETE operations are prohibited.',
    'Prohibits UPDATE operations on audit_logs'
);

SELECT throws_ok(
    $$DELETE FROM audit_logs WHERE id = '00000000-0000-0000-0000-000000000001'$$,
    'Audit logs are strictly immutable. UPDATE and DELETE operations are prohibited.',
    'Prohibits DELETE operations on audit_logs'
);

SELECT throws_ok(
    'TRUNCATE TABLE audit_logs',
    'Audit logs are strictly immutable. TRUNCATE operation is prohibited.',
    'Prohibits TRUNCATE operations on audit_logs'
);

-- -----------------------------------------------------------------------------
-- 3. Attendance Rule Validation Constraints & Cross-Tenant Relationships (6 tests)
-- -----------------------------------------------------------------------------
SELECT throws_ok(
    $$INSERT INTO attendance_rules (institute_id, scope_level, rule_type, rule_value)
      VALUES ('11111111-1111-1111-1111-111111111111', 'INSTITUTE', 'MINIMUM_PERCENTAGE', '{"percentage": 150}'::jsonb)$$,
    'Invalid MINIMUM_PERCENTAGE: percentage must be a number between 0 and 100',
    'Rejects MINIMUM_PERCENTAGE > 100'
);

SELECT throws_ok(
    $$INSERT INTO attendance_rules (institute_id, scope_level, rule_type, rule_value)
      VALUES ('11111111-1111-1111-1111-111111111111', 'INSTITUTE', 'MINIMUM_PERCENTAGE', '{"percentage": -5}'::jsonb)$$,
    'Invalid MINIMUM_PERCENTAGE: percentage must be a number between 0 and 100',
    'Rejects MINIMUM_PERCENTAGE < 0'
);

SELECT throws_ok(
    $$INSERT INTO attendance_rules (institute_id, scope_level, rule_type, rule_value)
      VALUES ('11111111-1111-1111-1111-111111111111', 'INSTITUTE', 'CONSECUTIVE_ABSENCE_ALERT', '{"threshold_days": 0}'::jsonb)$$,
    'Invalid CONSECUTIVE_ABSENCE_ALERT: threshold_days must be an integer >= 1',
    'Rejects CONSECUTIVE_ABSENCE_ALERT threshold < 1'
);

SELECT throws_ok(
    $$INSERT INTO attendance_rules (institute_id, scope_level, rule_type, rule_value)
      VALUES ('11111111-1111-1111-1111-111111111111', 'INSTITUTE', 'LATE_GRACE_MINUTES', '{"grace_minutes": 250}'::jsonb)$$,
    'Invalid LATE_GRACE_MINUTES: grace_minutes must be an integer between 0 and 180',
    'Rejects LATE_GRACE_MINUTES > 180'
);

SELECT throws_ok(
    $$INSERT INTO attendance_rules (institute_id, scope_level, branch_id, rule_type, rule_value)
      VALUES (
        '11111111-1111-1111-1111-111111111111', 
        'BRANCH', 
        '22222222-bbbb-2222-2222-222222222201',
        'MINIMUM_PERCENTAGE', 
        '{"percentage": 85}'::jsonb
      )$$,
    'Cross-tenant violation: branch 22222222-bbbb-2222-2222-222222222201 does not belong to institute 11111111-1111-1111-1111-111111111111',
    'Rejects cross-tenant branch reference'
);

SELECT throws_ok(
    $$INSERT INTO attendance_rules (institute_id, scope_level, course_id, rule_type, rule_value)
      VALUES (
        '22222222-2222-2222-2222-222222222222', 
        'COURSE', 
        '11111111-cccc-1111-1111-111111111101',
        'MINIMUM_PERCENTAGE', 
        '{"percentage": 85}'::jsonb
      )$$,
    'Cross-tenant violation: course 11111111-cccc-1111-1111-111111111101 does not belong to institute 22222222-2222-2222-2222-222222222222',
    'Rejects cross-tenant course reference'
);

-- -----------------------------------------------------------------------------
-- 4. Attendance Rule Resolution & 4-Tier Precedence (5 tests)
-- Hierarchy: Class (4) > Course (3) > Branch (2) > Institute (1)
-- -----------------------------------------------------------------------------

-- Level 4 (Class) Precedence: Class override beats parent rules
SELECT is(
    (resolve_effective_attendance_rule(
        '11111111-1111-1111-1111-111111111111'::uuid,
        '11111111-bbbb-1111-1111-111111111101'::uuid,
        '11111111-cccc-1111-1111-111111111101'::uuid,
        '11111111-dddd-1111-1111-111111111101'::uuid,
        'LATE_GRACE_MINUTES'
    ) ->> 'resolved_scope')::text,
    'CLASS',
    'Level 4 Class override wins precedence over parent scopes'
);

-- Level 3 (Course) Precedence: Course override resolves when no Class rule exists
SELECT is(
    (resolve_effective_attendance_rule(
        '11111111-1111-1111-1111-111111111111'::uuid,
        '11111111-bbbb-1111-1111-111111111101'::uuid,
        '11111111-cccc-1111-1111-111111111101'::uuid,
        '11111111-dddd-1111-1111-111111111101'::uuid,
        'CONSECUTIVE_ABSENCE_ALERT'
    ) ->> 'resolved_scope')::text,
    'COURSE',
    'Level 3 Course override wins precedence when class override is absent'
);

-- Level 2 (Branch) Precedence: Branch override resolves for North Campus (80%)
SELECT is(
    (resolve_effective_attendance_rule(
        '11111111-1111-1111-1111-111111111111'::uuid,
        '11111111-bbbb-1111-1111-111111111102'::uuid,
        NULL,
        NULL,
        'MINIMUM_PERCENTAGE'
    ) ->> 'resolved_scope')::text,
    'BRANCH',
    'Level 2 Branch override wins precedence over Institute default'
);

-- Level 1 (Institute Default) Fallback: Main Campus falls back to Institute default (75%)
SELECT is(
    (resolve_effective_attendance_rule(
        '11111111-1111-1111-1111-111111111111'::uuid,
        '11111111-bbbb-1111-1111-111111111101'::uuid,
        NULL,
        NULL,
        'MINIMUM_PERCENTAGE'
    ) ->> 'resolved_scope')::text,
    'INSTITUTE',
    'Level 1 Institute default falls back when no branch override is configured'
);

-- Inactive Rule Fallback: Inactive Class rule does not override parent active rule
INSERT INTO attendance_rules (id, institute_id, scope_level, class_id, rule_type, rule_value, is_active)
VALUES (
    '11111111-aaaa-1111-1111-111111111199',
    '11111111-1111-1111-1111-111111111111',
    'CLASS',
    '11111111-dddd-1111-1111-111111111101',
    'MINIMUM_PERCENTAGE',
    '{"percentage": 99}'::jsonb,
    false
);

SELECT is(
    (resolve_effective_attendance_rule(
        '11111111-1111-1111-1111-111111111111'::uuid,
        '11111111-bbbb-1111-1111-111111111101'::uuid,
        '11111111-cccc-1111-1111-111111111101'::uuid,
        '11111111-dddd-1111-1111-111111111101'::uuid,
        'MINIMUM_PERCENTAGE'
    ) ->> 'resolved_scope')::text,
    'INSTITUTE',
    'Inactive Class rule correctly ignored, falling back to active ancestor'
);

-- -----------------------------------------------------------------------------
-- 5. Cross-Tenant Isolation via RLS (4 tests)
-- -----------------------------------------------------------------------------
SET LOCAL ROLE authenticated;

-- Impersonate Tenant 1 Owner
SELECT set_test_claims(
    '11111111-0000-0000-0000-000000000001'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'OWNER'
);

SELECT is(
    (SELECT count(*)::int FROM institutes),
    1,
    'Tenant 1 owner sees only Tenant 1 institute'
);

SELECT is(
    (SELECT count(*)::int FROM branches),
    2,
    'Tenant 1 owner sees only Tenant 1 branches (2 branches)'
);

-- Impersonate Tenant 2 Owner
SELECT set_test_claims(
    '22222222-0000-0000-0000-000000000001'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    'OWNER'
);

SELECT is(
    (SELECT count(*)::int FROM branches),
    1,
    'Tenant 2 owner sees only Tenant 2 branch (1 branch)'
);

SELECT is(
    (SELECT count(*)::int FROM attendance_rules),
    0,
    'Tenant 2 owner sees zero attendance rules belonging to Tenant 1'
);

-- -----------------------------------------------------------------------------
-- 6. Branch Manager Scoping & Unassigned Branch Restrictions (3 tests)
-- -----------------------------------------------------------------------------

-- Impersonate Branch Manager Bob (Assigned to Main Campus ONLY)
SELECT set_test_claims(
    '11111111-0000-0000-0000-000000000002'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'BRANCH_MANAGER',
    ARRAY['11111111-bbbb-1111-1111-111111111101'::uuid]
);

SELECT is(
    (SELECT count(*)::int FROM branches),
    1,
    'Branch Manager assigned to Main Campus sees only Main Campus'
);

SELECT is(
    (SELECT count(*)::int FROM user_branch_assignments),
    1,
    'Branch Manager sees only branch assignments for Main Campus'
);

SELECT throws_matching(
    $$INSERT INTO attendance_rules (institute_id, scope_level, branch_id, rule_type, rule_value)
      VALUES (
        '11111111-1111-1111-1111-111111111111', 
        'BRANCH', 
        '11111111-bbbb-1111-1111-111111111102',
        'LATE_GRACE_MINUTES', 
        '{"grace_minutes": 10}'::jsonb
      )$$,
    'row-level security',
    'Branch Manager cannot insert attendance rules for unassigned branch'
);

-- -----------------------------------------------------------------------------
-- 7. Ordinary User (Student) Least Privilege Enforcement (2 tests)
-- -----------------------------------------------------------------------------

-- Impersonate Charlie (Student in Alpha Institute)
SELECT set_test_claims(
    '11111111-0000-0000-0000-000000000003'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'STUDENT'
);

SELECT throws_matching(
    $$INSERT INTO attendance_rules (institute_id, scope_level, rule_type, rule_value)
      VALUES (
        '11111111-1111-1111-1111-111111111111', 
        'INSTITUTE', 
        'LATE_GRACE_MINUTES', 
        '{"grace_minutes": 10}'::jsonb
      )$$,
    'row-level security',
    'Student role is rejected when attempting to insert attendance rules'
);

SELECT throws_matching(
    $$INSERT INTO branches (institute_id, name, code)
      VALUES (
        '11111111-1111-1111-1111-111111111111', 
        'Unauthorized Campus', 
        'ALPHA-UNAUTH'
      )$$,
    'row-level security',
    'Student role is rejected when attempting to insert branches'
);

-- -----------------------------------------------------------------------------
-- 8. Platform Super Admin Privileged Access (1 test)
-- -----------------------------------------------------------------------------

-- Impersonate Platform Super Admin
SELECT set_test_claims(
    '00000000-0000-0000-0000-000000000001'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'OWNER',
    '{}'::uuid[],
    true -- is_super_admin = true
);

SELECT is(
    (SELECT count(*)::int FROM institutes),
    2,
    'Platform super admin claim grants cross-tenant visibility across all institutes'
);

RESET ROLE;

-- -----------------------------------------------------------------------------
-- Complete pgTAP Execution
-- -----------------------------------------------------------------------------
SELECT * FROM finish();
ROLLBACK;
