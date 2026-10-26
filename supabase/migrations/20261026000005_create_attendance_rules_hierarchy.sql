-- =============================================================================
-- Migration: 20261026000005_create_attendance_rules_hierarchy.sql
-- Description: Establishes academic baseline references (courses, classes),
--              the 4-tier attendance-rule inheritance engine, validation triggers,
--              resolution function, audit history, and RLS policies.
-- Hierarchy: Institute Default -> Branch Override -> Course Override -> Class Override
-- Precedence: Class > Course > Branch > Institute
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Minimal Coherent Academic Baseline Entities (Courses & Classes)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    branch_id UUID REFERENCES branches(id) ON DELETE RESTRICT,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_course_code_per_institute UNIQUE (institute_id, code)
);

CREATE INDEX IF NOT EXISTS idx_courses_tenant ON courses(institute_id, branch_id);

CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    branch_id UUID REFERENCES branches(id) ON DELETE RESTRICT,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    sequence_order INT NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_class_name_per_course UNIQUE (course_id, name)
);

CREATE INDEX IF NOT EXISTS idx_classes_tenant ON classes(institute_id, branch_id, course_id);

-- -----------------------------------------------------------------------------
-- 2. Attendance Rules Data Model
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS attendance_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    scope_level VARCHAR(20) NOT NULL 
        CHECK (scope_level IN ('INSTITUTE', 'BRANCH', 'COURSE', 'CLASS')),
    branch_id UUID REFERENCES branches(id) ON DELETE RESTRICT,
    course_id UUID REFERENCES courses(id) ON DELETE RESTRICT,
    class_id UUID REFERENCES classes(id) ON DELETE RESTRICT,
    rule_type VARCHAR(50) NOT NULL 
        CHECK (rule_type IN (
            'MINIMUM_PERCENTAGE',
            'CONSECUTIVE_ABSENCE_ALERT',
            'LATE_GRACE_MINUTES',
            'HALF_DAY_THRESHOLD'
        )),
    rule_value JSONB NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    -- Scope consistency constraints
    CONSTRAINT chk_scope_identifiers CHECK (
        (scope_level = 'INSTITUTE' AND branch_id IS NULL AND course_id IS NULL AND class_id IS NULL) OR
        (scope_level = 'BRANCH'    AND branch_id IS NOT NULL AND course_id IS NULL AND class_id IS NULL) OR
        (scope_level = 'COURSE'    AND course_id IS NOT NULL AND class_id IS NULL) OR
        (scope_level = 'CLASS'     AND class_id IS NOT NULL)
    )
);

-- Unique composite index: exactly one active rule per rule_type at each hierarchy node
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_attendance_rule 
ON attendance_rules (
    institute_id, 
    scope_level, 
    COALESCE(branch_id, '00000000-0000-0000-0000-000000000000'::uuid),
    COALESCE(course_id, '00000000-0000-0000-0000-000000000000'::uuid),
    COALESCE(class_id,  '00000000-0000-0000-0000-000000000000'::uuid),
    rule_type
) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_attendance_rules_query 
ON attendance_rules (institute_id, scope_level, rule_type, is_active);

-- -----------------------------------------------------------------------------
-- 3. Validation Trigger for Rule Values & Cross-Tenant Integrity
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION validate_attendance_rule_payload()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_target_institute_id UUID;
BEGIN
    -- 1. Tenant ownership validation across referenced foreign keys
    IF NEW.branch_id IS NOT NULL THEN
        SELECT institute_id INTO v_target_institute_id FROM branches WHERE id = NEW.branch_id;
        IF v_target_institute_id IS NULL OR v_target_institute_id <> NEW.institute_id THEN
            RAISE EXCEPTION 'Cross-tenant violation: branch % does not belong to institute %', NEW.branch_id, NEW.institute_id;
        END IF;
    END IF;

    IF NEW.course_id IS NOT NULL THEN
        SELECT institute_id INTO v_target_institute_id FROM courses WHERE id = NEW.course_id;
        IF v_target_institute_id IS NULL OR v_target_institute_id <> NEW.institute_id THEN
            RAISE EXCEPTION 'Cross-tenant violation: course % does not belong to institute %', NEW.course_id, NEW.institute_id;
        END IF;
    END IF;

    IF NEW.class_id IS NOT NULL THEN
        SELECT institute_id INTO v_target_institute_id FROM classes WHERE id = NEW.class_id;
        IF v_target_institute_id IS NULL OR v_target_institute_id <> NEW.institute_id THEN
            RAISE EXCEPTION 'Cross-tenant violation: class % does not belong to institute %', NEW.class_id, NEW.institute_id;
        END IF;
    END IF;

    -- 2. Value boundary validation per rule_type
    IF NEW.rule_type = 'MINIMUM_PERCENTAGE' THEN
        IF NOT (NEW.rule_value ? 'percentage') OR 
           (NEW.rule_value ->> 'percentage')::NUMERIC < 0 OR 
           (NEW.rule_value ->> 'percentage')::NUMERIC > 100 THEN
            RAISE EXCEPTION 'Invalid MINIMUM_PERCENTAGE: percentage must be a number between 0 and 100';
        END IF;

    ELSIF NEW.rule_type = 'CONSECUTIVE_ABSENCE_ALERT' THEN
        IF NOT (NEW.rule_value ? 'threshold_days') OR 
           (NEW.rule_value ->> 'threshold_days')::INT < 1 THEN
            RAISE EXCEPTION 'Invalid CONSECUTIVE_ABSENCE_ALERT: threshold_days must be an integer >= 1';
        END IF;

    ELSIF NEW.rule_type = 'LATE_GRACE_MINUTES' THEN
        IF NOT (NEW.rule_value ? 'grace_minutes') OR 
           (NEW.rule_value ->> 'grace_minutes')::INT < 0 OR 
           (NEW.rule_value ->> 'grace_minutes')::INT > 180 THEN
            RAISE EXCEPTION 'Invalid LATE_GRACE_MINUTES: grace_minutes must be an integer between 0 and 180';
        END IF;

    ELSIF NEW.rule_type = 'HALF_DAY_THRESHOLD' THEN
        IF NOT (NEW.rule_value ? 'minimum_periods' OR NEW.rule_value ? 'minimum_minutes') THEN
            RAISE EXCEPTION 'Invalid HALF_DAY_THRESHOLD: must specify minimum_periods or minimum_minutes';
        END IF;
    END IF;

    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_attendance_rule ON attendance_rules;
CREATE TRIGGER trg_validate_attendance_rule
BEFORE INSERT OR UPDATE ON attendance_rules
FOR EACH ROW EXECUTE FUNCTION validate_attendance_rule_payload();

-- -----------------------------------------------------------------------------
-- 4. Attendance Rule Change History (Audit Log)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS attendance_rule_audit_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID NOT NULL,
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE RESTRICT,
    action VARCHAR(20) NOT NULL CHECK (action IN ('CREATED', 'UPDATED', 'DEACTIVATED', 'ACTIVATED')),
    scope_level VARCHAR(20) NOT NULL,
    rule_type VARCHAR(50) NOT NULL,
    old_value JSONB,
    new_value JSONB,
    old_is_active BOOLEAN,
    new_is_active BOOLEAN,
    changed_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_rule_history ON attendance_rule_audit_history(institute_id, rule_id, changed_at DESC);

CREATE OR REPLACE FUNCTION record_attendance_rule_history()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO attendance_rule_audit_history (
            rule_id, institute_id, action, scope_level, rule_type,
            old_value, new_value, old_is_active, new_is_active,
            changed_by_user_id, changed_at
        ) VALUES (
            NEW.id, NEW.institute_id, 'CREATED', NEW.scope_level, NEW.rule_type,
            NULL, NEW.rule_value, NULL, NEW.is_active,
            NEW.created_by_user_id, clock_timestamp()
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        DECLARE
            v_action VARCHAR(20) := 'UPDATED';
        BEGIN
            IF OLD.is_active = true AND NEW.is_active = false THEN
                v_action := 'DEACTIVATED';
            ELSIF OLD.is_active = false AND NEW.is_active = true THEN
                v_action := 'ACTIVATED';
            END IF;

            INSERT INTO attendance_rule_audit_history (
                rule_id, institute_id, action, scope_level, rule_type,
                old_value, new_value, old_is_active, new_is_active,
                changed_by_user_id, changed_at
            ) VALUES (
                NEW.id, NEW.institute_id, v_action, NEW.scope_level, NEW.rule_type,
                OLD.rule_value, NEW.rule_value, OLD.is_active, NEW.is_active,
                NEW.created_by_user_id, clock_timestamp()
            );
            RETURN NEW;
        END;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_record_attendance_rule_history ON attendance_rules;
CREATE TRIGGER trg_record_attendance_rule_history
AFTER INSERT OR UPDATE ON attendance_rules
FOR EACH ROW EXECUTE FUNCTION record_attendance_rule_history();

-- -----------------------------------------------------------------------------
-- 5. Deterministic Effective-Rule Resolution Engine
-- Precedence: Class (4) > Course (3) > Branch (2) > Institute (1)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION resolve_effective_attendance_rule(
    p_institute_id UUID,
    p_branch_id UUID,
    p_course_id UUID,
    p_class_id UUID,
    p_rule_type VARCHAR
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rule_value JSONB;
    v_effective_scope VARCHAR(20);
    v_derived_course_id UUID := p_course_id;
    v_derived_branch_id UUID := p_branch_id;
BEGIN
    -- If class_id is passed but course/branch omitted, derive them from class
    IF p_class_id IS NOT NULL AND (v_derived_course_id IS NULL OR v_derived_branch_id IS NULL) THEN
        SELECT course_id, branch_id INTO v_derived_course_id, v_derived_branch_id 
        FROM classes WHERE id = p_class_id;
    END IF;

    -- If course_id is passed but branch omitted, derive from course
    IF v_derived_course_id IS NOT NULL AND v_derived_branch_id IS NULL THEN
        SELECT branch_id INTO v_derived_branch_id 
        FROM courses WHERE id = v_derived_course_id;
    END IF;

    -- Level 4 (Highest Precedence): Class Override
    IF p_class_id IS NOT NULL THEN
        SELECT rule_value, scope_level INTO v_rule_value, v_effective_scope
        FROM attendance_rules
        WHERE institute_id = p_institute_id
          AND scope_level = 'CLASS'
          AND class_id = p_class_id
          AND rule_type = p_rule_type
          AND is_active = true;

        IF v_rule_value IS NOT NULL THEN
            RETURN jsonb_build_object(
                'resolved_value', v_rule_value,
                'resolved_scope', v_effective_scope,
                'rule_type', p_rule_type,
                'precedence_rank', 4
            );
        END IF;
    END IF;

    -- Level 3: Course Override
    IF v_derived_course_id IS NOT NULL THEN
        SELECT rule_value, scope_level INTO v_rule_value, v_effective_scope
        FROM attendance_rules
        WHERE institute_id = p_institute_id
          AND scope_level = 'COURSE'
          AND course_id = v_derived_course_id
          AND rule_type = p_rule_type
          AND is_active = true;

        IF v_rule_value IS NOT NULL THEN
            RETURN jsonb_build_object(
                'resolved_value', v_rule_value,
                'resolved_scope', v_effective_scope,
                'rule_type', p_rule_type,
                'precedence_rank', 3
            );
        END IF;
    END IF;

    -- Level 2: Branch Override
    IF v_derived_branch_id IS NOT NULL THEN
        SELECT rule_value, scope_level INTO v_rule_value, v_effective_scope
        FROM attendance_rules
        WHERE institute_id = p_institute_id
          AND scope_level = 'BRANCH'
          AND branch_id = v_derived_branch_id
          AND rule_type = p_rule_type
          AND is_active = true;

        IF v_rule_value IS NOT NULL THEN
            RETURN jsonb_build_object(
                'resolved_value', v_rule_value,
                'resolved_scope', v_effective_scope,
                'rule_type', p_rule_type,
                'precedence_rank', 2
            );
        END IF;
    END IF;

    -- Level 1 (Default): Institute-Wide Rule
    SELECT rule_value, scope_level INTO v_rule_value, v_effective_scope
    FROM attendance_rules
    WHERE institute_id = p_institute_id
      AND scope_level = 'INSTITUTE'
      AND rule_type = p_rule_type
      AND is_active = true;

    IF v_rule_value IS NOT NULL THEN
        RETURN jsonb_build_object(
            'resolved_value', v_rule_value,
            'resolved_scope', v_effective_scope,
            'rule_type', p_rule_type,
            'precedence_rank', 1
        );
    END IF;

    -- Level 0: No active rule configured at any tier
    RETURN NULL;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. Row-Level Security for Academic Baseline & Attendance Rules
-- -----------------------------------------------------------------------------

ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_rule_audit_history ENABLE ROW LEVEL SECURITY;

-- Courses RLS
CREATE POLICY policy_courses_select ON courses
FOR SELECT USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        (branch_id IS NULL OR has_branch_access(branch_id))
    )
);

CREATE POLICY policy_courses_modify ON courses
FOR ALL USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER') AND
        (branch_id IS NULL OR has_branch_access(branch_id))
    )
) WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER') AND
        (branch_id IS NULL OR has_branch_access(branch_id))
    )
);

-- Classes RLS
CREATE POLICY policy_classes_select ON classes
FOR SELECT USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        (branch_id IS NULL OR has_branch_access(branch_id))
    )
);

CREATE POLICY policy_classes_modify ON classes
FOR ALL USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER') AND
        (branch_id IS NULL OR has_branch_access(branch_id))
    )
) WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN', 'BRANCH_MANAGER') AND
        (branch_id IS NULL OR has_branch_access(branch_id))
    )
);

-- Attendance Rules RLS
CREATE POLICY policy_attendance_rules_select ON attendance_rules
FOR SELECT USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        (scope_level = 'INSTITUTE' OR has_branch_access(branch_id))
    )
);

CREATE POLICY policy_attendance_rules_insert ON attendance_rules
FOR INSERT WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        (
            current_user_role() IN ('OWNER', 'ADMIN') OR
            (current_user_role() = 'BRANCH_MANAGER' AND branch_id IS NOT NULL AND has_branch_access(branch_id))
        )
    )
);

CREATE POLICY policy_attendance_rules_update ON attendance_rules
FOR UPDATE USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        (
            current_user_role() IN ('OWNER', 'ADMIN') OR
            (current_user_role() = 'BRANCH_MANAGER' AND branch_id IS NOT NULL AND has_branch_access(branch_id))
        )
    )
) WITH CHECK (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        (
            current_user_role() IN ('OWNER', 'ADMIN') OR
            (current_user_role() = 'BRANCH_MANAGER' AND branch_id IS NOT NULL AND has_branch_access(branch_id))
        )
    )
);

-- Attendance Rule Audit History RLS (Strict Read-Only)
CREATE POLICY policy_attendance_rule_audit_select ON attendance_rule_audit_history
FOR SELECT USING (
    is_platform_super_admin() OR (
        institute_id = current_institute_id() AND
        current_user_role() IN ('OWNER', 'ADMIN')
    )
);
