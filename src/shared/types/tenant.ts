export type SystemRole =
  | "OWNER"
  | "ADMIN"
  | "BRANCH_MANAGER"
  | "TEACHER"
  | "ACCOUNTANT"
  | "RECEPTIONIST"
  | "STUDENT";

export type InstituteStatus =
  | "ACTIVE"
  | "TRIAL"
  | "SUSPENDED_OVERDUE"
  | "READ_ONLY"
  | "DECOMMISSIONED";

export type SubscriptionTier = "TRIAL" | "STARTER" | "GROWTH" | "ENTERPRISE";

export interface Institute {
  id: string;
  legal_name: string;
  brand_name: string;
  slug: string;
  status: InstituteStatus;
  subscription_tier: SubscriptionTier;
  trial_ends_at: string | null;
  max_students: number;
  max_branches: number;
  gstin: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface Branch {
  id: string;
  institute_id: string;
  name: string;
  code: string;
  is_main_branch: boolean;
  address_line1: string | null;
  city: string | null;
  state: string | null;
  postal_code: string | null;
  contact_phone: string | null;
  contact_email: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Course {
  id: string;
  institute_id: string;
  branch_id: string | null;
  code: string;
  name: string;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface ClassEntity {
  id: string;
  institute_id: string;
  branch_id: string | null;
  course_id: string;
  name: string;
  sequence_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type AttendanceScopeLevel = "INSTITUTE" | "BRANCH" | "COURSE" | "CLASS";

export type AttendanceRuleType =
  | "MINIMUM_PERCENTAGE"
  | "CONSECUTIVE_ABSENCE_ALERT"
  | "LATE_GRACE_MINUTES"
  | "HALF_DAY_THRESHOLD";

export interface AttendanceRule {
  id: string;
  institute_id: string;
  scope_level: AttendanceScopeLevel;
  branch_id: string | null;
  course_id: string | null;
  class_id: string | null;
  rule_type: AttendanceRuleType;
  rule_value: Record<string, unknown>;
  is_active: boolean;
  created_by_user_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface AttendanceRuleAuditHistory {
  id: string;
  rule_id: string;
  institute_id: string;
  action: "CREATED" | "UPDATED" | "DEACTIVATED" | "ACTIVATED";
  scope_level: AttendanceScopeLevel;
  rule_type: AttendanceRuleType;
  old_value: Record<string, unknown> | null;
  new_value: Record<string, unknown> | null;
  old_is_active: boolean | null;
  new_is_active: boolean | null;
  changed_by_user_id: string | null;
  changed_at: string;
}

export interface InstituteUser {
  id: string;
  institute_id: string;
  user_id: string;
  system_role: SystemRole;
  status: "INVITED" | "ACTIVE" | "SUSPENDED" | "TERMINATED";
  created_at: string;
  updated_at: string;
}

export interface UserBranchAssignment {
  id: string;
  institute_id: string;
  institute_user_id: string;
  branch_id: string;
  assigned_role: string;
  is_primary_branch: boolean;
  created_at: string;
}
