-- =============================================================================
-- Seed: supabase/seed.sql
-- Description: Deterministic synthetic test fixtures for multi-tenant testing
-- =============================================================================

-- Tenant 1: Alpha Institute
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

-- Tenant 2: Beta Academy (Completely isolated tenant)
INSERT INTO institutes (id, legal_name, brand_name, slug, status, subscription_tier, max_students, max_branches)
VALUES 
    ('22222222-2222-2222-2222-222222222222', 'Beta Learning Trust', 'Beta Academy', 'beta-academy', 'ACTIVE', 'STARTER', 200, 1)
ON CONFLICT (id) DO NOTHING;

-- Branch for Tenant 2
INSERT INTO branches (id, institute_id, name, code, is_main_branch, city, is_active)
VALUES 
    ('22222222-bbbb-2222-2222-222222222201', '22222222-2222-2222-2222-222222222222', 'Central Branch', 'BETA-CENTRAL', true, 'Nashik', true)
ON CONFLICT (id) DO NOTHING;
