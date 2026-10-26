-- =============================================================================
-- Migration: 20261026000001_create_tenants_and_branches.sql
-- Description: Creates root multi-tenant institutes and physical/operational branches
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Root Multi-Tenant Organization Table
CREATE TABLE IF NOT EXISTS institutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legal_name VARCHAR(255) NOT NULL,
    brand_name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'TRIAL', 'SUSPENDED_OVERDUE', 'READ_ONLY', 'DECOMMISSIONED')),
    subscription_tier VARCHAR(50) NOT NULL DEFAULT 'TRIAL'
        CHECK (subscription_tier IN ('TRIAL', 'STARTER', 'GROWTH', 'ENTERPRISE')),
    trial_ends_at TIMESTAMPTZ,
    max_students INT NOT NULL DEFAULT 100,
    max_branches INT NOT NULL DEFAULT 1,
    gstin VARCHAR(15),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_institutes_slug ON institutes(slug);
CREATE INDEX IF NOT EXISTS idx_institutes_status ON institutes(status);

-- Physical and Operational Branches Table
CREATE TABLE IF NOT EXISTS branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    is_main_branch BOOLEAN NOT NULL DEFAULT false,
    address_line1 TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_branch_code_per_institute UNIQUE (institute_id, code)
);

CREATE INDEX IF NOT EXISTS idx_branches_institute ON branches(institute_id);
CREATE INDEX IF NOT EXISTS idx_branches_composite ON branches(institute_id, is_active);
