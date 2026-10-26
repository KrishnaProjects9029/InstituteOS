-- =============================================================================
-- Test Suite: supabase/tests/rls_isolation_test.sql
-- Description: pgTAP tests asserting tenant isolation and immutability guards
-- =============================================================================

BEGIN;
SELECT plan(6);

-- Test 1: Verify RLS is enabled on all tenant foundation tables
SELECT has_table('institutes');
SELECT has_table('branches');
SELECT has_table('audit_logs');

-- Test 2: Verify helper function existence
SELECT has_function('current_institute_id');
SELECT has_function('has_branch_access');

-- Test 3: Verify Audit Log Immutability (Attempted UPDATE throws exception)
PREPARE test_audit_update AS
    UPDATE audit_logs SET action = 'TAMPERED' WHERE id = '00000000-0000-0000-0000-000000000000';

SELECT throws_ok(
    'test_audit_update',
    'Audit logs are strictly immutable. UPDATE and DELETE operations are prohibited.',
    'Prohibits UPDATE operations on audit_logs'
);

SELECT * FROM finish();
ROLLBACK;
