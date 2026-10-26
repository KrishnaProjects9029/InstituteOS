import { CheckSquare, ArrowDown, ShieldCheck, AlertCircle, Layers, GitBranch, BookOpen, GraduationCap } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/shared/ui/card";
import { Badge } from "@/shared/ui/badge";

export default async function AttendanceRulesPage({
  params,
}: {
  params: Promise<{ tenantSlug: string }>;
}) {
  const { tenantSlug } = await params;
  const isAlpha = tenantSlug === "alpha-institute";

  const hierarchyTiers = [
    {
      level: "CLASS",
      name: "Class Override (Highest Precedence)",
      scope: "Grade 10 - Section A (SCI-10)",
      rule: "Late Grace: 5 minutes",
      status: "ACTIVE",
      badgeVariant: "default" as const,
      icon: GraduationCap,
      description: "Overrides Institute default (15 min) for intense morning sessions.",
    },
    {
      level: "COURSE",
      name: "Course Override",
      scope: "Secondary Science (SCI-10)",
      rule: "Consecutive Absence Alert: 2 days",
      status: "ACTIVE",
      badgeVariant: "secondary" as const,
      icon: BookOpen,
      description: "Triggers immediate SMS alerts after 2 missed lab sessions.",
    },
    {
      level: "BRANCH",
      name: "Branch Override",
      scope: "North Campus (ALPHA-NORTH)",
      rule: "Minimum Attendance: 80%",
      status: "ACTIVE",
      badgeVariant: "secondary" as const,
      icon: GitBranch,
      description: "Campus-specific policy overriding the 75% institute baseline.",
    },
    {
      level: "INSTITUTE",
      name: "Institute Default (Baseline)",
      scope: isAlpha ? "Alpha Educational Foundation" : "Beta Learning Trust",
      rule: "Minimum Attendance: 75% | Late Grace: 15 min",
      status: "ACTIVE",
      badgeVariant: "outline" as const,
      icon: Layers,
      description: "Default fallback policy applied when no child overrides exist.",
    },
  ];

  return (
    <div className="space-y-6 max-w-6xl">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Attendance-Rule Hierarchical Inheritance
        </h1>
        <p className="text-sm text-muted-foreground">
          Evaluation Precedence: <strong>Class &gt; Course &gt; Branch &gt; Institute</strong>. The most specific valid active rule always wins.
        </p>
      </div>

      <div className="rounded-lg bg-blue-50 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-800 p-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <ShieldCheck className="h-5 w-5 text-primary" />
          <div className="text-xs">
            <span className="font-semibold text-blue-950 dark:text-blue-300">
              V1 Deterministic Inheritance Engine Active
            </span>
            <div className="text-blue-800 dark:text-blue-400">
              PostgreSQL function <code className="font-mono">resolve_effective_attendance_rule()</code> guarantees zero ambiguous resolution.
            </div>
          </div>
        </div>
        <Badge variant="success" className="text-xs shrink-0">
          V1 Verified
        </Badge>
      </div>

      <div className="space-y-4">
        {hierarchyTiers.map((tier, idx) => {
          const Icon = tier.icon;
          return (
            <div key={tier.level} className="relative">
              <Card className="border-slate-200 dark:border-slate-800">
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <div className="h-9 w-9 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-primary font-bold">
                        <Icon className="h-5 w-5" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <CardTitle className="text-base">{tier.name}</CardTitle>
                          <Badge variant={tier.badgeVariant} className="text-[10px]">
                            {tier.level}
                          </Badge>
                        </div>
                        <CardDescription className="text-xs font-medium text-slate-700 dark:text-slate-300 mt-0.5">
                          Scope: {tier.scope}
                        </CardDescription>
                      </div>
                    </div>
                    <Badge variant="success" className="text-xs">
                      {tier.status}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="space-y-1 text-xs">
                  <div className="font-semibold text-slate-900 dark:text-white">
                    Effective Setting: <span className="text-primary">{tier.rule}</span>
                  </div>
                  <p className="text-muted-foreground">{tier.description}</p>
                </CardContent>
              </Card>

              {idx < hierarchyTiers.length - 1 && (
                <div className="flex justify-center my-1.5">
                  <ArrowDown className="h-4 w-4 text-muted-foreground animate-bounce" />
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
