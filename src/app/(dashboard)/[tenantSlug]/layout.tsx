import Link from "next/link";
import { 
  Building2, 
  LayoutDashboard, 
  GitBranch, 
  ShieldCheck, 
  CheckSquare,
  Users, 
  Settings, 
  LogOut, 
  ChevronDown,
  Layers
} from "lucide-react";
import { Badge } from "@/shared/ui/badge";

export default async function TenantDashboardLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ tenantSlug: string }>;
}) {
  const { tenantSlug } = await params;
  const isAlpha = tenantSlug === "alpha-institute";
  const tenantName = isAlpha ? "Alpha Educational Foundation" : "Beta Learning Trust";
  const tier = isAlpha ? "GROWTH" : "STARTER";

  return (
    <div className="flex min-h-screen bg-slate-50 dark:bg-slate-950">
      {/* Sidebar Navigation */}
      <aside className="w-64 border-r bg-white dark:bg-slate-900 flex flex-col shrink-0">
        <div className="h-16 border-b flex items-center px-6 gap-3">
          <div className="h-9 w-9 rounded-lg bg-primary text-white flex items-center justify-center font-bold shadow-sm">
            <Building2 className="h-5 w-5" />
          </div>
          <div className="min-w-0">
            <div className="font-bold text-sm truncate text-slate-900 dark:text-white">
              {tenantName}
            </div>
            <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
              <span className="truncate">/{tenantSlug}</span>
              <Badge variant="outline" className="text-[10px] px-1 py-0">
                {tier}
              </Badge>
            </div>
          </div>
        </div>

        {/* Branch Context Selector */}
        <div className="p-4 border-b bg-slate-50/50 dark:bg-slate-900/50">
          <label className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground mb-1 block">
            Active Branch Context
          </label>
          <div className="flex items-center justify-between p-2 rounded-md border bg-white dark:bg-slate-800 text-xs shadow-sm">
            <div className="flex items-center gap-2 truncate">
              <div className="h-2 w-2 rounded-full bg-emerald-500" />
              <span className="font-medium truncate">
                {isAlpha ? "Main Campus (ALPHA-MAIN)" : "Central Branch (BETA-CENTRAL)"}
              </span>
            </div>
            <ChevronDown className="h-3.5 w-3.5 text-muted-foreground" />
          </div>
        </div>

        {/* Main Nav Links (V1 Modules) */}
        <nav className="flex-1 p-3 space-y-1">
          <Link
            href={`/${tenantSlug}`}
            className="flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium bg-primary/10 text-primary transition-colors"
          >
            <LayoutDashboard className="h-4 w-4" />
            <span>Dashboard Overview</span>
          </Link>

          <Link
            href={`/${tenantSlug}/branches`}
            className="flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <GitBranch className="h-4 w-4 text-muted-foreground" />
            <span>Branches & Campuses</span>
          </Link>

          <Link
            href={`/${tenantSlug}/attendance-rules`}
            className="flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <CheckSquare className="h-4 w-4 text-muted-foreground" />
            <span>Attendance Hierarchy</span>
          </Link>

          <Link
            href={`/${tenantSlug}/audit`}
            className="flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <ShieldCheck className="h-4 w-4 text-muted-foreground" />
            <span>Security & Audit Logs</span>
          </Link>

          <div className="pt-4 pb-1 px-3 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
            Upcoming Modules (V2–V5)
          </div>

          <div className="flex items-center justify-between px-3 py-2 rounded-md text-sm text-muted-foreground/60 cursor-not-allowed">
            <div className="flex items-center gap-3">
              <Users className="h-4 w-4" />
              <span>Admissions & Students</span>
            </div>
            <Badge variant="outline" className="text-[10px] text-muted-foreground/60">
              V2
            </Badge>
          </div>

          <div className="flex items-center justify-between px-3 py-2 rounded-md text-sm text-muted-foreground/60 cursor-not-allowed">
            <div className="flex items-center gap-3">
              <Layers className="h-4 w-4" />
              <span>Academics & Exams</span>
            </div>
            <Badge variant="outline" className="text-[10px] text-muted-foreground/60">
              V3
            </Badge>
          </div>
        </nav>

        {/* User Profile Footer */}
        <div className="p-4 border-t flex items-center justify-between bg-slate-50/50 dark:bg-slate-900/50">
          <div className="flex items-center gap-2 min-w-0">
            <div className="h-8 w-8 rounded-full bg-slate-200 dark:bg-slate-700 flex items-center justify-center font-bold text-xs">
              AD
            </div>
            <div className="min-w-0">
              <div className="text-xs font-semibold truncate">Admin User</div>
              <div className="text-[10px] text-muted-foreground truncate">
                Institute Owner
              </div>
            </div>
          </div>
          <Link href="/login" className="text-muted-foreground hover:text-foreground">
            <LogOut className="h-4 w-4" />
          </Link>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-16 border-b bg-white dark:bg-slate-900 flex items-center justify-between px-8">
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <span>Workspaces</span>
            <span>/</span>
            <span className="font-semibold text-foreground">{tenantName}</span>
          </div>
          <div className="flex items-center gap-3">
            <Badge variant="success" className="text-xs">
              RLS Policy Active
            </Badge>
          </div>
        </header>

        <main className="flex-1 p-8 overflow-y-auto">{children}</main>
      </div>
    </div>
  );
}
