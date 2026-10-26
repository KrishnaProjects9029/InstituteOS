-- =============================================================================
-- Migration: 20261026000007_create_academic_structure_and_students.sql
-- Description: Establishes Phase 2.1 Academic Structure & Student Admissions:
--              1. Academic Years & Class Divisions
--              2. Student Profiles & Enrollments
--              3. Admission number uniqueness per institute
--              4. Concurrency-safe automatic sequential roll number generation
--              5. Administrative roll number override auditing
--              6. Enrollment integrity & cross-tenant validation triggers
--              7. Row-Level Security policies & FORCE RLS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Academic Years Table
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL, -- e.g. "2026-2027"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT uq_academic_year_name UNIQUE (institute_id, name),
    CONSTRAINT chk_academic_year_dates CHECK (end_date > start_date)
);

CREATE INDEX IF NOT EXISTS idx_academic_years_tenant ON academic_years(institute_id, is_current);

-- -----------------------------------------------------------------------------
-- 2. Class Divisions (Sections) Table
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS divisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
    name VARCHAR(50) NOT NULL, -- e.g. "Section A", "Morning"
    capacity INT NOT NULL DEFAULT 60 CHECK (capacity > 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT uq_division_name_per_class UNIQUE (class_id, name)
);

CREATE INDEX IF NOT EXISTS idx_divisions_tenant ON divisions(institute_id, class_id);

-- -----------------------------------------------------------------------------
-- 3. Student Profiles Table
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS student_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Optional portal login
    admission_number VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20) NOT NULL CHECK (gender IN ('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY')),
    blood_group VARCHAR(10),
    guardian_name VARCHAR(255) NOT NULL,
    guardian_phone VARCHAR(20) NOT NULL,
    guardian_email VARCHAR(255),
    emergency_contact VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'ALUMNI', 'EXPELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT uq_student_adm_no UNIQUE (institute_id, admission_number)
);

CREATE INDEX IF NOT EXISTS idx_student_profiles_tenant ON student_profiles(institute_id, status);
CREATE INDEX IF NOT EXISTS idx_student_profiles_adm_no ON student_profiles(institute_id, admission_number);
CREATE INDEX IF NOT EXISTS idx_student_profiles_name ON student_profiles(institute_id, last_name, first_name);

-- -----------------------------------------------------------------------------
-- 4. Student Enrollments Table
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS student_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    student_profile_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE RESTRICT,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE RESTRICT,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
    division_id UUID NOT NULL REFERENCES divisions(id) ON DELETE RESTRICT,
    roll_number INT NOT NULL,
    is_roll_number_manual BOOLEAN NOT NULL DEFAULT false,
    enrollment_status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE'
        CHECK (enrollment_status IN ('ACTIVE', 'PROMOTED', 'DETAINED', 'TRANSFERRED', 'COMPLETED', 'DROPPED')),
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    -- Unique enrollment per student per academic year
    CONSTRAINT uq_student_year_enrollment UNIQUE (student_profile_id, academic_year_id),
    -- Unique roll number per division per academic year
    CONSTRAINT uq_roll_number_per_division UNIQUE (academic_year_id, class_id, division_id, roll_number)
);

CREATE INDEX IF NOT EXISTS idx_student_enrollments_lookup ON student_enrollments(institute_id, branch_id, class_id, division_id);
CREATE INDEX IF NOT EXISTS idx_student_enrollments_student ON student_enrollments(student_profile_id);

-- -----------------------------------------------------------------------------
-- 5. Automatic Sequential Roll Number Generation & Audit Trigger
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION assign_enrollment_roll_number()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_next_roll INT;
    v_division_capacity INT;
    v_current_count INT;
BEGIN
    -- Concurrency Protection: Lock the division row to serialize concurrent enrollments into the same division
    SELECT capacity INTO v_division_capacity 
    FROM divisions 
    WHERE id = NEW.division_id 
    FOR UPDATE;

    IF v_division_capacity IS NULL THEN
        RAISE EXCEPTION 'Target division % not found', NEW.division_id;
    END IF;

    -- Validate capacity
    SELECT COUNT(*) INTO v_current_count 
    FROM student_enrollments 
    WHERE academic_year_id = NEW.academic_year_id 
      AND class_id = NEW.class_id 
      AND division_id = NEW.division_id
      AND enrollment_status = 'ACTIVE';

    IF TG_OP = 'INSERT' AND v_current_count >= v_division_capacity THEN
        RAISE EXCEPTION 'Division capacity exceeded. Maximum capacity is %', v_division_capacity;
    END IF;

    -- Automatic Sequential Generation if not manually assigned
    IF NEW.roll_number IS NULL OR NEW.roll_number <= 0 THEN
        SELECT COALESCE(MAX(roll_number), 0) + 1 INTO v_next_roll
        FROM student_enrollments
        WHERE academic_year_id = NEW.academic_year_id
          AND class_id = NEW.class_id
          AND division_id = NEW.division_id;

        NEW.roll_number := v_next_roll;
        NEW.is_roll_number_manual := false;
    ELSE
        -- Manual roll number was specified
        NEW.is_roll_number_manual := true;
        
        -- Audit manual assignment or change
        INSERT INTO audit_logs (
            institute_id, branch_id, action, entity_name, entity_id, new_data
        ) VALUES (
            NEW.institute_id, NEW.branch_id, 
            CASE WHEN TG_OP = 'INSERT' THEN 'MANUAL_ROLL_NUMBER_ASSIGNED' ELSE 'ROLL_NUMBER_MODIFIED' END,
            'student_enrollments', NEW.id,
            jsonb_build_object(
                'student_profile_id', NEW.student_profile_id,
                'class_id', NEW.class_id,
                'division_id', NEW.division_id,
                'roll_number', NEW.roll_number,
                'is_manual', true
            )
        );
    END IF;

    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_assign_enrollment_roll_number ON student_enrollments;
CREATE TRIGGER trg_assign_enrollment_roll_number
BEFORE INSERT OR UPDATE OF roll_number ON student_enrollments
FOR EACH ROW EXECUTE FUNCTION assign_enrollment_roll_number();

-- -----------------------------------------------------------------------------
-- 6. Integrity & Cross-Tenant Validation Trigger
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION validate_student_enrollment_integrity()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_branch_inst UUID;
    v_student_inst UUID;
    v_year_inst UUID;
    v_class_inst UUID;
    v_class_branch UUID;
    v_div_class UUID;
    v_div_inst UUID;
BEGIN
    -- 1. Validate branch ownership
    SELECT institute_id INTO v_branch_inst FROM branches WHERE id = NEW.branch_id;
    IF v_branch_inst IS NULL OR v_branch_inst <> NEW.institute_id THEN
        RAISE EXCEPTION 'Cross-tenant violation: branch % does not belong to institute %', NEW.branch_id, NEW.institute_id;
    END IF;

    -- 2. Validate student profile ownership
    SELECT institute_id INTO v_student_inst FROM student_profiles WHERE id = NEW.student_profile_id;
    IF v_student_inst IS NULL OR v_student_inst <> NEW.institute_id THEN
        RAISE EXCEPTION 'Cross-tenant violation: student % does not belong to institute %', NEW.student_profile_id, NEW.institute_id;
    END IF;

    -- 3. Validate academic year ownership
    SELECT institute_id INTO v_year_inst FROM academic_years WHERE id = NEW.academic_year_id;
    IF v_year_inst IS NULL OR v_year_inst <> NEW.institute_id THEN
        RAISE EXCEPTION 'Cross-tenant violation: academic_year % does not belong to institute %', NEW.academic_year_id, NEW.institute_id;
    END IF;

    -- 4. Validate class ownership & branch alignment
    SELECT institute_id, branch_id INTO v_class_inst, v_class_branch FROM classes WHERE id = NEW.class_id;
    IF v_class_inst IS NULL OR v_class_inst <> NEW.institute_id THEN
        RAISE EXCEPTION 'Cross-tenant violation: class % does not belong to institute %', NEW.class_id, NEW.institute_id;
    END IF;
    IF v_class_branch IS NOT NULL AND v_class_branch <> NEW.branch_id THEN
        RAISE EXCEPTION 'Hierarchy mismatch: class % is bound to branch %, not enrollment branch %', NEW.class_id, v_class_branch, NEW.branch_id;
    END IF;

    -- 5. Validate division belongs to class and institute
    SELECT class_id, institute_id INTO v_div_class, v_div_inst FROM divisions WHERE id = NEW.division_id;
    IF v_div_inst IS NULL OR v_div_inst <> NEW.institute_id THEN
        RAISE EXCEPTION 'Cross-tenant violation: division % does not belong to institute %', NEW.division_id, NEW.institute_id;
    END IF;
    IF v_div_class <> NEW.class_id THEN
        RAISE EXCEPTION 'Hierarchy mismatch: division % belongs to class %, not class %', NEW.division_id, v_div_class, NEW.class_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_student_enrollment ON student_enrollments;
CREATE TRIGGER trg_validate_student_enrollment
BEFORE INSERT OR UPDATE ON student_enrollments
FOR EACH ROW EXECUTE FUNCTION validate_student_enrollment_integrity();

-- -----------------------------------------------------------------------------
-- 7. Row-Level Security (RLS) Policies
-- -----------------------------------------------------------------------------

ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE divisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_enrollments ENABLE ROW LEVEL SECURITY;

-- Apply FORCE ROW LEVEL SECURITY to prevent table owner bypass
ALTER TABLE academic_years FORCE ROW LEVEL SECURITY;
ALTER TABLE divisions FORCE ROW LEVEL SECURITY;
ALTER TABLE student_profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE student_enrollments FORCE ROW LEVEL SECURITY;

-- 7.1 Academic Years Policies
CREATE POLICY policy_academic_years_select ON academic_years
FOR SELECT USING (
    is_platform_super_admin() OR institute_id = current_institute_id()
);

CREATE POLICY policy_academic_years_modify ON academic_years
FOR ALL USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN')
    )
) WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN')
    )
);

-- 7.2 Divisions Policies
CREATE POLICY policy_divisions_select ON divisions
FOR SELECT USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        EXISTS (
            SELECT 1 FROM classes c 
            WHERE c.id = divisions.class_id 
              AND (c.branch_id IS NULL OR has_branch_access(c.branch_id))
        )
    )
);

CREATE POLICY policy_divisions_modify ON divisions
FOR ALL USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER') AND
        EXISTS (
            SELECT 1 FROM classes c 
            WHERE c.id = divisions.class_id 
              AND (c.branch_id IS NULL OR has_branch_access(c.branch_id))
        )
    )
) WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER') AND
        EXISTS (
            SELECT 1 FROM classes c 
            WHERE c.id = divisions.class_id 
              AND (c.branch_id IS NULL OR has_branch_access(c.branch_id))
        )
    )
);

-- 7.3 Student Profiles Policies
CREATE POLICY policy_student_profiles_select ON student_profiles
FOR SELECT USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        (
            current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'TEACHER', 'ACCOUNTANT', 'RECEPTIONIST')
            OR user_id = auth_uid()
        )
    )
);

CREATE POLICY policy_student_profiles_insert ON student_profiles
FOR INSERT WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'RECEPTIONIST')
    )
);

CREATE POLICY policy_student_profiles_update ON student_profiles
FOR UPDATE USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'RECEPTIONIST')
    )
) WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'RECEPTIONIST')
    )
);

CREATE POLICY policy_student_profiles_delete ON student_profiles
FOR DELETE USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN')
    )
);

-- 7.4 Student Enrollments Policies
CREATE POLICY policy_student_enrollments_select ON student_enrollments
FOR SELECT USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        has_branch_access(branch_id)
    )
);

CREATE POLICY policy_student_enrollments_insert ON student_enrollments
FOR INSERT WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'RECEPTIONIST') AND
        has_branch_access(branch_id)
    )
);

CREATE POLICY policy_student_enrollments_update ON student_enrollments
FOR UPDATE USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'RECEPTIONIST') AND
        has_branch_access(branch_id)
    )
) WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER', 'RECEPTIONIST') AND
        has_branch_access(branch_id)
    )
);

CREATE POLICY policy_student_enrollments_delete ON student_enrollments
FOR DELETE USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN') AND
        has_branch_access(branch_id)
    )
);
