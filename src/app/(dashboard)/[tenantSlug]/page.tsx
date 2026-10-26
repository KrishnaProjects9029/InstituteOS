import { 
  Building2, 
  GitBranch, 
  ShieldAlert, 
  ShieldCheck, 
  CheckCircle2, 
  Users, 
  Clock 
} from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/shared/ui/card";
import { Badge } from "@/shared/ui/badge";

export default async function TenantOverviewPage({
  params,
}: {
  params: Promise<{ tenantSlug: string }>;
}) {
  const { tenantSlug } = await params;
  const isAlpha = tenantSlug === "alpha-institute";
  const tenantName = isAlpha ? "Alpha Educational Foundation" : "Beta Learning Trust";
  const branchCount = isAlpha ? 2 : 1;

  return (
    <div className="space-y-8 max-w-6xl">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Workspace Overview
        </h1>
        <p className="text-sm text-muted-foreground">
          Core tenant foundation, branch scoping, and security policies for {tenantName}.
        </p>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Configured Branches
            </CardTitle>
            <GitBranch className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{branchCount}</div>
            <p className="text-xs text-muted-foreground mt-1">
              {isAlpha ? "Main Campus & North Campus" : "Central Campus"}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Tenant Status
            </CardTitle>
            <CheckCircle2 className="h-4 w-4 text-emerald-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold flex items-center gap-2">
              <span>Active</span>
              <Badge variant="success" className="text-[10px]">
                {isAlpha ? "GROWTH TIER" : "STARTER TIER"}
              </Badge>
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Zero silent deletion protection enabled
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Data Isolation
            </CardTitle>
            <ShieldCheck className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">100% RLS</div>
            <p className="text-xs text-muted-foreground mt-1">
              Database Row-Level Security active
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Current Roadmap Gate
            </CardTitle>
            <Clock className="h-4 w-4 text-amber-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">V1 Active</div>
            <p className="text-xs text-muted-foreground mt-1">
              Core foundation ready for V2 unlock
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Security & RLS Invariant Verification */}
      <Card className="border-slate-200 dark:border-slate-800">
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <ShieldCheck className="h-5 w-5 text-primary" />
            <span>Active Tenant Isolation & Row-Level Security Verification</span>
          </CardTitle>
          <CardDescription>
            The PostgreSQL database engine dynamically evaluates tenant and branch claims for every query.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
            <div className="p-4 rounded-lg border bg-slate-50 dark:bg-slate-900/50 space-y-1">
              <div className="font-semibold text-slate-800 dark:text-slate-200">
                Tenant Context Invariant
              </div>
              <div className="text-muted-foreground">
                Current Scope: <code className="bg-slate-200 dark:bg-slate-800 px-1 py-0.5 rounded">{tenantSlug}</code>
              </div>
              <p className="text-muted-foreground pt-1">
                Any attempted query against records belonging to another tenant automatically returns 0 rows at the database level.
              </p>
            </div>

            <div className="p-4 rounded-lg border bg-slate-50 dark:bg-slate-900/50 space-y-1">
              <div className="font-semibold text-slate-800 dark:text-slate-200">
                Audit Trail Immutability
              </div>
              <div className="text-muted-foreground">
                Status: <span className="text-emerald-600 font-semibold">Protected by Database Triggers</span>
              </div>
              <p className="text-muted-foreground pt-1">
                Direct UPDATE and DELETE operations on <code className="bg-slate-200 dark:bg-slate-800 px-1 py-0.5 rounded">audit_logs</code> trigger PostgreSQL exceptions.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
