import { SystemRole } from "./tenant";

export interface CustomJwtClaims {
  sub: string;
  email: string;
  app_metadata: {
    institute_id?: string;
    system_role?: SystemRole;
    assigned_branches?: string[];
    is_super_admin?: boolean;
  };
}

export interface UserSession {
  userId: string;
  email: string;
  instituteId: string | null;
  role: SystemRole | null;
  assignedBranches: string[];
  isSuperAdmin: boolean;
}
