// =============================================================================
// File: src/shared/types/student.ts
// Description: Type definitions for Phase 2.1 Academic Structure & Student Admissions
// =============================================================================

export interface AcademicYear {
  id: string;
  institute_id: string;
  name: string;
  start_date: string;
  end_date: string;
  is_current: boolean;
  created_at: string;
  updated_at: string;
}

export interface Division {
  id: string;
  institute_id: string;
  class_id: string;
  name: string;
  capacity: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type StudentGender = "MALE" | "FEMALE" | "OTHER" | "PREFER_NOT_TO_SAY";
export type StudentStatus = "ACTIVE" | "INACTIVE" | "ALUMNI" | "EXPELLED";
export type EnrollmentStatus = "ACTIVE" | "PROMOTED" | "DETAINED" | "TRANSFERRED" | "COMPLETED" | "DROPPED";

export interface StudentProfile {
  id: string;
  institute_id: string;
  user_id?: string | null;
  admission_number: string;
  first_name: string;
  last_name: string;
  date_of_birth: string;
  gender: StudentGender;
  blood_group?: string | null;
  guardian_name: string;
  guardian_phone: string;
  guardian_email?: string | null;
  emergency_contact?: string | null;
  address?: string | null;
  city?: string | null;
  status: StudentStatus;
  created_at: string;
  updated_at: string;
}

export interface StudentEnrollment {
  id: string;
  institute_id: string;
  branch_id: string;
  student_profile_id: string;
  academic_year_id: string;
  class_id: string;
  division_id: string;
  roll_number: number;
  is_roll_number_manual: boolean;
  enrollment_status: EnrollmentStatus;
  enrolled_at: string;
  updated_at: string;
}

export interface EnrolledStudentItem {
  id: string;
  admission_number: string;
  first_name: string;
  last_name: string;
  gender: StudentGender;
  status: StudentStatus;
  roll_number: number;
  branch_name: string;
  class_name: string;
  division_name: string;
  guardian_name: string;
  guardian_phone: string;
  enrolled_at: string;
}

export interface AdmissionFormData {
  first_name: string;
  last_name: string;
  date_of_birth: string;
  gender: StudentGender;
  blood_group?: string;
  admission_number: string;
  guardian_name: string;
  guardian_phone: string;
  guardian_email?: string;
  emergency_contact?: string;
  address?: string;
  city?: string;
  branch_id: string;
  academic_year_id: string;
  class_id: string;
  division_id: string;
  manual_roll_number?: number;
}
