-- =============================================================================
-- Test Suite: supabase/tests/v2_student_admissions_test.sql
-- Description: Phase 2.1 Academic Structure & Student Admissions Verification Suite
--              1. Schema tables & integrity constraints
--              2. Admission number uniqueness per institute
--              3. Automatic sequential roll number generation
--              4. Administrative roll number override & audit logging
--              5. Roll number uniqueness per division constraint
--              6. Cross-tenant & hierarchy mismatch rejection
--              7. Cross-tenant isolation via RLS
--              8. Branch Manager scoping enforcement
--              9. Least privilege enforcement for non-admin roles
-- =============================================================================

BEGIN;
SELECT plan(20);

-- Ensure authenticated role has standard schema grants for RLS evaluation
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- -----------------------------------------------------------------------------
-- Helper Function: Set JWT Claims for RLS Impersonation Testing
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_v2_test_claims(
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
-- 1. Table Schema Verification (4 tests)
-- -----------------------------------------------------------------------------
SELECT has_table('academic_years', 'academic_years table exists');
SELECT has_table('divisions', 'divisions table exists');
SELECT has_table('student_profiles', 'student_profiles table exists');
SELECT has_table('student_enrollments', 'student_enrollments table exists');

-- -----------------------------------------------------------------------------
-- 2. Setup Baseline Test Entities for Phase 2.1
-- -----------------------------------------------------------------------------
INSERT INTO academic_years (id, institute_id, name, start_date, end_date, is_current)
VALUES 
    ('11111111-9999-1111-1111-111111111101', '11111111-1111-1111-1111-111111111111', '2026-2027', '2026-06-01', '2027-04-30', true),
    ('22222222-9999-2222-2222-222222222201', '22222222-2222-2222-2222-222222222222', '2026-2027', '2026-06-01', '2027-04-30', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO divisions (id, institute_id, class_id, name, capacity)
VALUES 
    ('11111111-8888-1111-1111-111111111101', '11111111-1111-1111-1111-111111111111', '11111111-dddd-1111-1111-111111111101', 'Section A', 50),
    ('11111111-8888-1111-1111-111111111102', '11111111-1111-1111-1111-111111111111', '11111111-dddd-1111-1111-111111111101', 'Section B', 50)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 3. Admission Number Uniqueness Constraints (2 tests)
-- -----------------------------------------------------------------------------
INSERT INTO student_profiles (
    id, institute_id, admission_number, first_name, last_name, 
    date_of_birth, gender, guardian_name, guardian_phone
) VALUES (
    '11111111-7777-1111-1111-111111111101', '11111111-1111-1111-1111-111111111111', 'ADM-2026-001', 
    'Aarav', 'Sharma', '2010-05-15', 'MALE', 'Rajesh Sharma', '+919876543210'
);

-- Duplicate admission number in same institute must fail
SELECT throws_ok(
    $$INSERT INTO student_profiles (
        institute_id, admission_number, first_name, last_name, 
        date_of_birth, gender, guardian_name, guardian_phone
      ) VALUES (
        '11111111-1111-1111-1111-111111111111', 'ADM-2026-001', 
        'Duplicate', 'Student', '2010-01-01', 'FEMALE', 'Guardian', '+919999999999'
      )$$,
    '23505', -- unique_violation SQLSTATE
    NULL,
    'Rejects duplicate admission number within the same institute'
);

-- Same admission number in Tenant 2 (Beta) must succeed (proving institute-scoped uniqueness)
SELECT lives_ok(
    $$INSERT INTO student_profiles (
        id, institute_id, admission_number, first_name, last_name, 
        date_of_birth, gender, guardian_name, guardian_phone
      ) VALUES (
        '22222222-7777-2222-2222-222222222201', '22222222-2222-2222-2222-222222222222', 'ADM-2026-001', 
        'Vikram', 'BetaStudent', '2010-03-20', 'MALE', 'Suresh', '+919111111111'
      )$$,
    'Allows identical admission number across different institutes'
);

-- -----------------------------------------------------------------------------
-- 4. Automatic Sequential Roll Number Generation (3 tests)
-- -----------------------------------------------------------------------------

-- Enroll Student 1 without roll number -> should receive 1
INSERT INTO student_enrollments (
    id, institute_id, branch_id, student_profile_id, academic_year_id, class_id, division_id
) VALUES (
    '11111111-6666-1111-1111-111111111101',
    '11111111-1111-1111-1111-111111111111',
    '11111111-bbbb-1111-1111-111111111101',
    '11111111-7777-1111-1111-111111111101',
    '11111111-9999-1111-1111-111111111101',
    '11111111-dddd-1111-1111-111111111101',
    '11111111-8888-1111-1111-111111111101'
);

SELECT is(
    (SELECT roll_number FROM student_enrollments WHERE id = '11111111-6666-1111-1111-111111111101'),
    1,
    'First student in division automatically receives sequential roll number 1'
);

-- Create and Enroll Student 2 without roll number -> should receive 2
INSERT INTO student_profiles (
    id, institute_id, admission_number, first_name, last_name, 
    date_of_birth, gender, guardian_name, guardian_phone
) VALUES (
    '11111111-7777-1111-1111-111111111102', '11111111-1111-1111-1111-111111111111', 'ADM-2026-002', 
    'Priya', 'Patel', '2010-08-22', 'FEMALE', 'Mahesh Patel', '+919876543211'
);

INSERT INTO student_enrollments (
    id, institute_id, branch_id, student_profile_id, academic_year_id, class_id, division_id
) VALUES (
    '11111111-6666-1111-1111-111111111102',
    '11111111-1111-1111-1111-111111111111',
    '11111111-bbbb-1111-1111-111111111101',
    '11111111-7777-1111-1111-111111111102',
    '11111111-9999-1111-1111-111111111101',
    '11111111-dddd-1111-1111-111111111101',
    '11111111-8888-1111-1111-111111111101'
);

SELECT is(
    (SELECT roll_number FROM student_enrollments WHERE id = '11111111-6666-1111-1111-111111111102'),
    2,
    'Second student in same division automatically receives sequential roll number 2'
);

-- Enroll Student into Section B -> should receive roll number 1 (separate sequence per division)
INSERT INTO student_profiles (
    id, institute_id, admission_number, first_name, last_name, 
    date_of_birth, gender, guardian_name, guardian_phone
) VALUES (
    '11111111-7777-1111-1111-111111111103', '11111111-1111-1111-1111-111111111111', 'ADM-2026-003', 
    'Rohan', 'Joshi', '2010-11-10', 'MALE', 'Sunil Joshi', '+919876543212'
);

INSERT INTO student_enrollments (
    id, institute_id, branch_id, student_profile_id, academic_year_id, class_id, division_id
) VALUES (
    '11111111-6666-1111-1111-111111111103',
    '11111111-1111-1111-1111-111111111111',
    '11111111-bbbb-1111-1111-111111111101',
    '11111111-7777-1111-1111-111111111103',
    '11111111-9999-1111-1111-111111111101',
    '11111111-dddd-1111-1111-111111111101',
    '11111111-8888-1111-1111-111111111102' -- Section B!
);

SELECT is(
    (SELECT roll_number FROM student_enrollments WHERE id = '11111111-6666-1111-1111-111111111103'),
    1,
    'Student in Section B starts separate sequential roll number 1'
);

-- -----------------------------------------------------------------------------
-- 5. Administrative Roll Number Override & Audit Trail (2 tests)
-- -----------------------------------------------------------------------------

-- Create Student 4 and enroll with manual override roll_number = 25
INSERT INTO student_profiles (
    id, institute_id, admission_number, first_name, last_name, 
    date_of_birth, gender, guardian_name, guardian_phone
) VALUES (
    '11111111-7777-1111-1111-111111111104', '11111111-1111-1111-1111-111111111111', 'ADM-2026-004', 
    'Ananya', 'Deshmukh', '2010-09-05', 'FEMALE', 'Kiran', '+919876543213'
);

INSERT INTO student_enrollments (
    id, institute_id, branch_id, student_profile_id, academic_year_id, class_id, division_id, roll_number
) VALUES (
    '11111111-6666-1111-1111-111111111104',
    '11111111-1111-1111-1111-111111111111',
    '11111111-bbbb-1111-1111-111111111101',
    '11111111-7777-1111-1111-111111111104',
    '11111111-9999-1111-1111-111111111101',
    '11111111-dddd-1111-1111-111111111101',
    '11111111-8888-1111-1111-111111111101',
    25 -- Explicit manual override
);

SELECT is(
    (SELECT roll_number FROM student_enrollments WHERE id = '11111111-6666-1111-1111-111111111104'),
    25,
    'Manual roll number override is preserved'
);

SELECT is(
    (SELECT count(*)::int FROM audit_logs 
     WHERE entity_id = '11111111-6666-1111-1111-111111111104' 
       AND action = 'MANUAL_ROLL_NUMBER_ASSIGNED'),
    1,
    'Manual roll number assignment generates an immutable audit log record'
);

-- -----------------------------------------------------------------------------
-- 6. Roll Number Uniqueness Constraint (1 test)
-- -----------------------------------------------------------------------------

-- Attempting duplicate roll_number = 25 in same division must fail
INSERT INTO student_profiles (
    id, institute_id, admission_number, first_name, last_name, 
    date_of_birth, gender, guardian_name, guardian_phone
) VALUES (
    '11111111-7777-1111-1111-111111111105', '11111111-1111-1111-1111-111111111111', 'ADM-2026-005', 
    'Tanvi', 'Kulkarni', '2010-04-12', 'FEMALE', 'Nitin', '+919876543214'
);

SELECT throws_ok(
    $$INSERT INTO student_enrollments (
        institute_id, branch_id, student_profile_id, academic_year_id, class_id, division_id, roll_number
      ) VALUES (
        '11111111-1111-1111-1111-111111111111',
        '11111111-bbbb-1111-1111-111111111101',
        '11111111-7777-1111-1111-111111111105',
        '11111111-9999-1111-1111-111111111101',
        '11111111-dddd-1111-1111-111111111101',
        '11111111-8888-1111-1111-111111111101',
        25 -- Conflict with Student 4!
      )$$,
    '23505', -- unique_violation SQLSTATE
    NULL,
    'Rejects duplicate roll number within the same division'
);

-- -----------------------------------------------------------------------------
-- 7. Cross-Tenant Integrity Validation Triggers (2 tests)
-- -----------------------------------------------------------------------------

-- Cross-tenant branch in enrollment
SELECT throws_ok(
    $$INSERT INTO student_enrollments (
        institute_id, branch_id, student_profile_id, academic_year_id, class_id, division_id
      ) VALUES (
        '11111111-1111-1111-1111-111111111111',
        '22222222-bbbb-2222-2222-222222222201', -- Branch belongs to Tenant 2!
        '11111111-7777-1111-1111-111111111105',
        '11111111-9999-1111-1111-111111111101',
        '11111111-dddd-1111-1111-111111111101',
        '11111111-8888-1111-1111-111111111101'
      )$$,
    'Cross-tenant violation: branch 22222222-bbbb-2222-2222-222222222201 does not belong to institute 11111111-1111-1111-1111-111111111111',
    'Rejects enrollment with cross-tenant branch reference'
);

-- Cross-tenant academic year in enrollment
SELECT throws_ok(
    $$INSERT INTO student_enrollments (
        institute_id, branch_id, student_profile_id, academic_year_id, class_id, division_id
      ) VALUES (
        '11111111-1111-1111-1111-111111111111',
        '11111111-bbbb-1111-1111-111111111101',
        '11111111-7777-1111-1111-111111111105',
        '22222222-9999-2222-2222-222222222201', -- Academic Year belongs to Tenant 2!
        '11111111-dddd-1111-1111-111111111101',
        '11111111-8888-1111-1111-111111111101'
      )$$,
    'Cross-tenant violation: academic_year 22222222-9999-2222-2222-222222222201 does not belong to institute 11111111-1111-1111-1111-111111111111',
    'Rejects enrollment with cross-tenant academic year reference'
);

-- -----------------------------------------------------------------------------
-- 8. Cross-Tenant Isolation via RLS (2 tests)
-- -----------------------------------------------------------------------------
SET LOCAL ROLE authenticated;

-- Impersonate Tenant 1 Owner
SELECT set_v2_test_claims(
    '11111111-0000-0000-0000-000000000001'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'OWNER'
);

SELECT is(
    (SELECT count(*)::int FROM student_profiles),
    5,
    'Tenant 1 owner sees only Tenant 1 student profiles (5 students)'
);

-- Impersonate Tenant 2 Owner
SELECT set_v2_test_claims(
    '22222222-0000-0000-0000-000000000001'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    'OWNER'
);

SELECT is(
    (SELECT count(*)::int FROM student_profiles),
    1,
    'Tenant 2 owner sees only Tenant 2 student profile (1 student)'
);

-- -----------------------------------------------------------------------------
-- 9. Branch Manager Scoping Enforcement (2 tests)
-- -----------------------------------------------------------------------------

-- Impersonate Branch Manager Bob (Assigned to Main Campus ONLY)
SELECT set_v2_test_claims(
    '11111111-0000-0000-0000-000000000002'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'BRANCH_MANAGER',
    ARRAY['11111111-bbbb-1111-1111-111111111101'::uuid]
);

SELECT is(
    (SELECT count(*)::int FROM student_enrollments),
    4,
    'Branch Manager sees enrollments for Main Campus'
);

-- Branch Manager attempts to enroll a student into North Campus (unassigned branch)
SELECT throws_matching(
    $$INSERT INTO student_enrollments (
        institute_id, branch_id, student_profile_id, academic_year_id, class_id, division_id
      ) VALUES (
        '11111111-1111-1111-1111-111111111111',
        '11111111-bbbb-1111-1111-111111111102', -- North Campus!
        '11111111-7777-1111-1111-111111111105',
        '11111111-9999-1111-1111-111111111101',
        '11111111-dddd-1111-1111-111111111101',
        '11111111-8888-1111-1111-111111111101'
      )$$,
    'row-level security',
    'Branch Manager cannot create enrollments in an unassigned branch'
);

-- -----------------------------------------------------------------------------
-- 10. Least Privilege Enforcement for Student Role (2 tests)
-- -----------------------------------------------------------------------------

-- Impersonate Charlie (Student in Alpha Institute)
SELECT set_v2_test_claims(
    '11111111-0000-0000-0000-000000000003'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'STUDENT'
);

SELECT throws_matching(
    $$INSERT INTO student_profiles (
        institute_id, admission_number, first_name, last_name, 
        date_of_birth, gender, guardian_name, guardian_phone
      ) VALUES (
        '11111111-1111-1111-1111-111111111111', 'ADM-HACK-001', 
        'Hacker', 'Student', '2010-01-01', 'MALE', 'Guardian', '+919876543219'
      )$$,
    'row-level security',
    'Student role is rejected when attempting to create student profiles'
);

SELECT throws_matching(
    $$INSERT INTO academic_years (
        institute_id, name, start_date, end_date
      ) VALUES (
        '11111111-1111-1111-1111-111111111111', '2030-2031', '2030-06-01', '2031-04-30'
      )$$,
    'row-level security',
    'Student role is rejected when attempting to create academic years'
);

RESET ROLE;

-- -----------------------------------------------------------------------------
-- Complete pgTAP Execution
-- -----------------------------------------------------------------------------
SELECT * FROM finish();
ROLLBACK;
