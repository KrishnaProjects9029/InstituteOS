-- =============================================================================
-- Seed: supabase/seed.sql
-- Description: Deterministic synthetic test fixtures for multi-tenant testing
--              including tenant hierarchy, academic entities, attendance rules,
--              synthetic auth users, profiles, and branch assignments.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tenant 1: Alpha Institute
-- -----------------------------------------------------------------------------
INSERT INTO institutes (id, legal_name, brand_name, slug, status, subscription_tier, max_students, max_branches)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Alpha Educational Foundation', 'Alpha Institute', 'alpha-institute', 'ACTIVE', 'GROWTH', 500, 5)
ON CONFLICT (id) DO NOTHING;

-- Branches for Tenant 1
INSERT INTO branches (id, institute_id, name, code, is_main_branch, city, is_active)
VALUES 
    ('11111111-bbbb-1111-1111-111111111101', '11111111-1111-1111-1111-111111111111', 'Main Campus', 'ALPHA-MAIN', true, 'Pune', true),
    ('11111111-bbbb-1111-1111-111111111102', '11111111-1111-1111-1111-111111111111', 'North Campus', 'ALPHA-NORTH', false, 'Mumbai', true)
ON CONFLICT (id) DO NOTHING;

-- Courses for Tenant 1
INSERT INTO courses (id, institute_id, branch_id, code, name)
VALUES 
    ('11111111-cccc-1111-1111-111111111101', '11111111-1111-1111-1111-111111111111', '11111111-bbbb-1111-1111-111111111101', 'SCI-10', 'Secondary Science')
ON CONFLICT (id) DO NOTHING;

-- Classes for Tenant 1
INSERT INTO classes (id, institute_id, branch_id, course_id, name, sequence_order)
VALUES 
    ('11111111-dddd-1111-1111-111111111101', '11111111-1111-1111-1111-111111111111', '11111111-bbbb-1111-1111-111111111101', '11111111-cccc-1111-1111-111111111101', 'Grade 10 - Section A', 1)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2. Attendance Rules Hierarchy for Tenant 1 (Alpha Institute)
-- -----------------------------------------------------------------------------

-- Level 1: Institute Default (75% minimum)
INSERT INTO attendance_rules (id, institute_id, scope_level, rule_type, rule_value, is_active)
VALUES (
    '11111111-aaaa-1111-1111-111111111101',
    '11111111-1111-1111-1111-111111111111',
    'INSTITUTE',
    'MINIMUM_PERCENTAGE',
    '{"percentage": 75}'::jsonb,
    true
) ON CONFLICT (id) DO NOTHING;

-- Level 2: Branch Override for North Campus (80% minimum)
INSERT INTO attendance_rules (id, institute_id, scope_level, branch_id, rule_type, rule_value, is_active)
VALUES (
    '11111111-aaaa-1111-1111-111111111102',
    '11111111-1111-1111-1111-111111111111',
    'BRANCH',
    '11111111-bbbb-1111-1111-111111111102',
    'MINIMUM_PERCENTAGE',
    '{"percentage": 80}'::jsonb,
    true
) ON CONFLICT (id) DO NOTHING;

-- Level 3: Course Override for Secondary Science (Consecutive Absence Alert = 2 days)
INSERT INTO attendance_rules (id, institute_id, scope_level, course_id, rule_type, rule_value, is_active)
VALUES (
    '11111111-aaaa-1111-1111-111111111103',
    '11111111-1111-1111-1111-111111111111',
    'COURSE',
    '11111111-cccc-1111-1111-111111111101',
    'CONSECUTIVE_ABSENCE_ALERT',
    '{"threshold_days": 2}'::jsonb,
    true
) ON CONFLICT (id) DO NOTHING;

-- Level 4: Class Override for Grade 10-A (Late Grace = 5 minutes)
INSERT INTO attendance_rules (id, institute_id, scope_level, class_id, rule_type, rule_value, is_active)
VALUES (
    '11111111-aaaa-1111-1111-111111111104',
    '11111111-1111-1111-1111-111111111111',
    'CLASS',
    '11111111-dddd-1111-1111-111111111101',
    'LATE_GRACE_MINUTES',
    '{"grace_minutes": 5}'::jsonb,
    true
) ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 3. Tenant 2: Beta Academy (Completely isolated tenant)
-- -----------------------------------------------------------------------------
INSERT INTO institutes (id, legal_name, brand_name, slug, status, subscription_tier, max_students, max_branches)
VALUES 
    ('22222222-2222-2222-2222-222222222222', 'Beta Learning Trust', 'Beta Academy', 'beta-academy', 'ACTIVE', 'STARTER', 200, 1)
ON CONFLICT (id) DO NOTHING;

-- Branch for Tenant 2
INSERT INTO branches (id, institute_id, name, code, is_main_branch, city, is_active)
VALUES 
    ('22222222-bbbb-2222-2222-222222222201', '22222222-2222-2222-2222-222222222222', 'Central Branch', 'BETA-CENTRAL', true, 'Nashik', true)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 4. Synthetic IAM Fixtures (Auth Users, Profiles, Memberships, Branch Assignments)
-- -----------------------------------------------------------------------------

-- Create dummy users in auth.users if auth schema is present
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        INSERT INTO auth.users (id, aud, role, email, encrypted_password, created_at, updated_at)
        VALUES
            ('11111111-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'owner@alpha.edu', '', clock_timestamp(), clock_timestamp()),
            ('11111111-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'mgr.main@alpha.edu', '', clock_timestamp(), clock_timestamp()),
            ('11111111-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'student@alpha.edu', '', clock_timestamp(), clock_timestamp()),
            ('11111111-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'mgr.north@alpha.edu', '', clock_timestamp(), clock_timestamp()),
            ('22222222-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'owner@beta.edu', '', clock_timestamp(), clock_timestamp())
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- Public User Profiles
INSERT INTO users (id, email, first_name, last_name, is_super_admin)
VALUES
    ('11111111-0000-0000-0000-000000000001', 'owner@alpha.edu', 'Alice', 'AlphaOwner', false),
    ('11111111-0000-0000-0000-000000000002', 'mgr.main@alpha.edu', 'Bob', 'MainManager', false),
    ('11111111-0000-0000-0000-000000000003', 'student@alpha.edu', 'Charlie', 'Student', false),
    ('11111111-0000-0000-0000-000000000004', 'mgr.north@alpha.edu', 'Diana', 'NorthManager', false),
    ('22222222-0000-0000-0000-000000000001', 'owner@beta.edu', 'David', 'BetaOwner', false)
ON CONFLICT (id) DO NOTHING;

-- Institute User Memberships
INSERT INTO institute_users (id, institute_id, user_id, system_role, status)
VALUES
    ('11111111-uuuu-1111-1111-111111111101', '11111111-1111-1111-1111-111111111111', '11111111-0000-0000-0000-000000000001', 'OWNER', 'ACTIVE'),
    ('11111111-uuuu-1111-1111-111111111102', '11111111-1111-1111-1111-111111111111', '11111111-0000-0000-0000-000000000002', 'BRANCH_MANAGER', 'ACTIVE'),
    ('11111111-uuuu-1111-1111-111111111103', '11111111-1111-1111-1111-111111111111', '11111111-0000-0000-0000-000000000003', 'STUDENT', 'ACTIVE'),
    ('11111111-uuuu-1111-1111-111111111104', '11111111-1111-1111-1111-111111111111', '11111111-0000-0000-0000-000000000004', 'BRANCH_MANAGER', 'ACTIVE'),
    ('22222222-uuuu-2222-2222-222222222201', '22222222-2222-2222-2222-222222222222', '22222222-0000-0000-0000-000000000001', 'OWNER', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

-- User Branch Assignments
-- Bob is assigned ONLY to Alpha Main Campus
INSERT INTO user_branch_assignments (id, institute_id, institute_user_id, branch_id, assigned_role, is_primary_branch)
VALUES
    ('11111111-bba0-1111-1111-111111111101', '11111111-1111-1111-1111-111111111111', '11111111-uuuu-1111-1111-111111111102', '11111111-bbbb-1111-1111-111111111101', 'BRANCH_MANAGER', true),
    ('11111111-bba0-1111-1111-111111111102', '11111111-1111-1111-1111-111111111111', '11111111-uuuu-1111-1111-111111111104', '11111111-bbbb-1111-1111-111111111102', 'BRANCH_MANAGER', true)
ON CONFLICT (id) DO NOTHING;
