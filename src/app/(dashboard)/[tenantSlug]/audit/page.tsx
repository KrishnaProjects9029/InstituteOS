import { ShieldCheck, Lock, Clock, UserCheck, Terminal } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/shared/ui/card";
import { Badge } from "@/shared/ui/badge";

export default async function AuditLogsPage({
  params,
}: {
  params: Promise<{ tenantSlug: string }>;
}) {
  const { tenantSlug } = await params;

  const mockLogs = [
    {
      id: "log-001",
      action: "TENANT_INITIALIZED",
      entityName: "institutes",
      entityId: "11111111-1111-1111-1111-111111111111",
      user: "system_provisioner",
      timestamp: "2026-10-26 09:30:00 UTC",
      ipAddress: "127.0.0.1",
      details: { status: "ACTIVE", tier: "GROWTH" },
    },
    {
      id: "log-002",
      action: "BRANCH_CONFIGURED",
      entityName: "branches",
      entityId: "11111111-bbbb-1111-1111-111111111101",
      user: "owner@alpha.edu.in",
      timestamp: "2026-10-26 09:35:12 UTC",
      ipAddress: "103.21.244.2",
      details: { code: "ALPHA-MAIN", is_main_branch: true },
    },
    {
      id: "log-003",
      action: "RLS_POLICY_VALIDATION",
      entityName: "pg_policy",
      entityId: "policy_branches_select",
      user: "automated_ci_test",
      timestamp: "2026-10-26 09:40:05 UTC",
      ipAddress: "127.0.0.1",
      details: { result: "100% Negative Tests Passed", leaks: 0 },
    },
  ];

  return (
    <div className="space-y-6 max-w-6xl">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Security & Immutable Audit Logs
        </h1>
        <p className="text-sm text-muted-foreground">
          Tamper-proof event logs capturing tenant operations, role assignments, and security validations.
        </p>
      </div>

      <div className="rounded-lg bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800 p-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <ShieldCheck className="h-5 w-5 text-emerald-600" />
          <div className="text-xs">
            <span className="font-semibold text-emerald-900 dark:text-emerald-300">
              Database Immutability Guard Active
            </span>
            <div className="text-emerald-700 dark:text-emerald-400">
              Direct SQL mutations (UPDATE / DELETE) on audit logs are rejected by PostgreSQL triggers.
            </div>
          </div>
        </div>
        <Badge variant="success" className="text-xs shrink-0">
          Trigger Armed
        </Badge>
      </div>

      <Card className="border-slate-200 dark:border-slate-800">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Terminal className="h-4 w-4 text-primary" />
            <span>Recent System Events</span>
          </CardTitle>
          <CardDescription>
            Audit events scoped to tenant: <code className="font-mono text-xs">{tenantSlug}</code>
          </CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y text-xs">
            {mockLogs.map((log) => (
              <div key={log.id} className="p-4 hover:bg-slate-50 dark:hover:bg-slate-900/50 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <Badge variant="default" className="text-[10px] font-mono">
                      {log.action}
                    </Badge>
                    <span className="font-semibold text-slate-800 dark:text-slate-200">
                      {log.entityName}
                    </span>
                    <span className="text-muted-foreground font-mono text-[11px]">
                      ({log.entityId.slice(0, 8)}...)
                    </span>
                  </div>
                  <div className="text-muted-foreground flex items-center gap-3 text-[11px]">
                    <span className="flex items-center gap-1">
                      <UserCheck className="h-3 w-3" /> {log.user}
                    </span>
                    <span className="flex items-center gap-1">
                      <Clock className="h-3 w-3" /> {log.timestamp}
                    </span>
                    <span>IP: {log.ipAddress}</span>
                  </div>
                </div>

                <div className="bg-slate-100 dark:bg-slate-800 px-3 py-1.5 rounded font-mono text-[11px] text-slate-700 dark:text-slate-300">
                  {JSON.stringify(log.details)}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
