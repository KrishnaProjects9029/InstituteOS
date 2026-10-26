import { GitBranch, MapPin, Phone, Mail, CheckCircle2, Plus } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/shared/ui/card";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";

export default async function BranchesPage({
  params,
}: {
  params: Promise<{ tenantSlug: string }>;
}) {
  const { tenantSlug } = await params;
  const isAlpha = tenantSlug === "alpha-institute";

  const branches = isAlpha
    ? [
        {
          id: "11111111-bbbb-1111-1111-111111111101",
          name: "Main Campus",
          code: "ALPHA-MAIN",
          isMain: true,
          city: "Pune",
          address: "Shivajinagar, Pune, Maharashtra 411005",
          phone: "+91 20 2550 0000",
          email: "main.campus@alpha.edu.in",
          isActive: true,
        },
        {
          id: "11111111-bbbb-1111-1111-111111111102",
          name: "North Campus",
          code: "ALPHA-NORTH",
          isMain: false,
          city: "Mumbai",
          address: "Andheri East, Mumbai, Maharashtra 400069",
          phone: "+91 22 2820 0000",
          email: "north.campus@alpha.edu.in",
          isActive: true,
        },
      ]
    : [
        {
          id: "22222222-bbbb-2222-2222-222222222201",
          name: "Central Branch",
          code: "BETA-CENTRAL",
          isMain: true,
          city: "Nashik",
          address: "College Road, Nashik, Maharashtra 422005",
          phone: "+91 253 257 0000",
          email: "info@beta.edu.in",
          isActive: true,
        },
      ];

  return (
    <div className="space-y-6 max-w-6xl">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
            Branches & Campuses
          </h1>
          <p className="text-sm text-muted-foreground">
            Manage physical and operational campuses. Staff and operational records are partitioned by branch.
          </p>
        </div>
        <Button size="sm" className="gap-2">
          <Plus className="h-4 w-4" /> Add Branch
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {branches.map((branch) => (
          <Card key={branch.id} className="border-slate-200 dark:border-slate-800">
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <CardTitle className="text-base">{branch.name}</CardTitle>
                    {branch.isMain && (
                      <Badge variant="default" className="text-[10px]">
                        Headquarters
                      </Badge>
                    )}
                  </div>
                  <CardDescription className="text-xs font-mono mt-0.5">
                    Code: {branch.code}
                  </CardDescription>
                </div>
                <Badge variant={branch.isActive ? "success" : "outline"} className="text-xs">
                  {branch.isActive ? "Active" : "Inactive"}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-2 text-xs text-muted-foreground">
              <div className="flex items-center gap-2">
                <MapPin className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                <span>{branch.address}</span>
              </div>
              <div className="flex items-center gap-2">
                <Phone className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                <span>{branch.phone}</span>
              </div>
              <div className="flex items-center gap-2">
                <Mail className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                <span>{branch.email}</span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
