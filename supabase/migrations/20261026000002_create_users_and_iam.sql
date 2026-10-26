-- =============================================================================
-- Migration: 20261026000002_create_users_and_iam.sql
-- Description: Creates user profiles, institute memberships, and branch assignments
-- =============================================================================

-- Global User Profile Table (linked to Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    is_super_admin BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Institute-User Mapping Table (Defines institutional role)
CREATE TABLE IF NOT EXISTS institute_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    system_role VARCHAR(50) NOT NULL 
        CHECK (system_role IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'TEACHER', 'ACCOUNTANT', 'RECEPTIONIST', 'STUDENT')),
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'TERMINATED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_user_per_institute UNIQUE (institute_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_institute_users_institute ON institute_users(institute_id);
CREATE INDEX IF NOT EXISTS idx_institute_users_user ON institute_users(user_id);
CREATE INDEX IF NOT EXISTS idx_institute_users_role ON institute_users(institute_id, system_role);

-- Staff Branch Assignments Table (Restricts staff to specific campuses)
CREATE TABLE IF NOT EXISTS user_branch_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    institute_user_id UUID NOT NULL REFERENCES institute_users(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    assigned_role VARCHAR(50) NOT NULL,
    is_primary_branch BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_user_branch_assignment UNIQUE (institute_user_id, branch_id)
);

CREATE INDEX IF NOT EXISTS idx_user_branches_composite ON user_branch_assignments(institute_id, branch_id);
CREATE INDEX IF NOT EXISTS idx_user_branches_user ON user_branch_assignments(institute_user_id);
