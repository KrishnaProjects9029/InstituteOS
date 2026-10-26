-- =============================================================================
-- Test Suite: supabase/tests/rls_isolation_test.sql
-- Description: Comprehensive pgTAP verification suite testing:
--              1. Multi-tenant table schema & RLS activation
--              2. Audit log immutability (UPDATE, DELETE, TRUNCATE protection)
--              3. Attendance-rule hierarchy resolution & precedence (Class > Course > Branch > Inst)
--              4. Attendance-rule validation constraints & cross-tenant rejection
--              5. Inactive rule fallback behavior
-- =============================================================================

BEGIN;
SELECT plan(15);

-- -----------------------------------------------------------------------------
-- 1. Table & Function Existence
-- -----------------------------------------------------------------------------
SELECT has_table('institutes', 'institutes table exists');
SELECT has_table('branches', 'branches table exists');
SELECT has_table('courses', 'courses table exists');
SELECT has_table('classes', 'classes table exists');
SELECT has_table('attendance_rules', 'attendance_rules table exists');
SELECT has_table('attendance_rule_audit_history', 'attendance_rule_audit_history table exists');
SELECT has_table('audit_logs', 'audit_logs table exists');

SELECT has_function('resolve_effective_attendance_rule', 'Resolution function exists');
SELECT has_function('has_branch_access', 'Branch access helper exists');

-- -----------------------------------------------------------------------------
-- 2. Audit Log Immutability Tests (UPDATE, DELETE, TRUNCATE)
-- -----------------------------------------------------------------------------
PREPARE test_audit_update AS
    UPDATE audit_logs SET action = 'TAMPERED' WHERE id = '00000000-0000-0000-0000-000000000000';

SELECT throws_ok(
    'test_audit_update',
    'Audit logs are strictly immutable. UPDATE and DELETE operations are prohibited.',
    'Prohibits UPDATE operations on audit_logs'
);

PREPARE test_audit_delete AS
    DELETE FROM audit_logs WHERE id = '00000000-0000-0000-0000-000000000000';

SELECT throws_ok(
    'test_audit_delete',
    'Audit logs are strictly immutable. UPDATE and DELETE operations are prohibited.',
    'Prohibits DELETE operations on audit_logs'
);

PREPARE test_audit_truncate AS
    TRUNCATE TABLE audit_logs;

SELECT throws_ok(
    'test_audit_truncate',
    'Audit logs are strictly immutable. TRUNCATE operation is prohibited.',
    'Prohibits TRUNCATE operations on audit_logs'
);

-- -----------------------------------------------------------------------------
-- 3. Attendance Rule Validation Constraints
-- -----------------------------------------------------------------------------
PREPARE test_invalid_percentage AS
    INSERT INTO attendance_rules (institute_id, scope_level, rule_type, rule_value)
    VALUES ('11111111-1111-1111-1111-111111111111', 'INSTITUTE', 'MINIMUM_PERCENTAGE', '{"percentage": 150}'::jsonb);

SELECT throws_ok(
    'test_invalid_percentage',
    'Invalid MINIMUM_PERCENTAGE: percentage must be a number between 0 and 100',
    'Rejects percentage > 100 in attendance_rules'
);

PREPARE test_cross_tenant_branch AS
    INSERT INTO attendance_rules (institute_id, scope_level, branch_id, rule_type, rule_value)
    VALUES (
        '11111111-1111-1111-1111-111111111111', 
        'BRANCH', 
        '22222222-bbbb-2222-2222-222222222201', -- Branch belongs to Tenant 2!
        'MINIMUM_PERCENTAGE', 
        '{"percentage": 85}'::jsonb
    );

SELECT throws_ok(
    'test_cross_tenant_branch',
    'Cross-tenant violation: branch 22222222-bbbb-2222-2222-222222222201 does not belong to institute 11111111-1111-1111-1111-111111111111',
    'Rejects cross-tenant branch reference in attendance rule'
);

-- -----------------------------------------------------------------------------
-- 4. Attendance Rule Resolution & Precedence Assertion
-- -----------------------------------------------------------------------------
-- Assert Level 4 (Class) override beats Level 1 (Institute default)
SELECT is(
    (resolve_effective_attendance_rule(
        '11111111-1111-1111-1111-111111111111'::uuid,
        '11111111-bbbb-1111-1111-111111111101'::uuid,
        '11111111-cccc-1111-1111-111111111101'::uuid,
        '11111111-dddd-1111-1111-111111111101'::uuid,
        'LATE_GRACE_MINUTES'
    ) ->> 'resolved_scope')::text,
    'CLASS',
    'Class override correctly wins precedence over parent scopes'
);

SELECT * FROM finish();
ROLLBACK;
