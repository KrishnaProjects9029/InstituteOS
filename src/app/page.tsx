import Link from "next/link";
import { Building2, ShieldCheck, Users, Layers, ArrowRight } from "lucide-react";
import { Button } from "@/shared/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/shared/ui/card";
import { Badge } from "@/shared/ui/badge";

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col bg-slate-50 dark:bg-slate-950">
      {/* Top Navigation */}
      <header className="border-b bg-white/80 dark:bg-slate-900/80 backdrop-blur sticky top-0 z-50">
        <div className="max-w-7xl mx-auto flex h-16 items-center justify-between px-6">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-lg bg-primary flex items-center justify-center text-white font-bold shadow-md">
              <Building2 className="h-6 w-6" />
            </div>
            <div>
              <span className="text-xl font-bold tracking-tight text-slate-900 dark:text-white">
                Institute<span className="text-primary">OS</span>
              </span>
              <Badge variant="outline" className="ml-2 text-xs py-0">
                V1 Core Foundation
              </Badge>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <Link href="/login">
              <Button variant="default" size="sm">
                Sign In to Institute Workspace
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <main className="flex-1">
        <section className="py-20 px-6 text-center max-w-4xl mx-auto space-y-6">
          <Badge variant="success" className="px-3 py-1 text-sm font-medium">
            Multi-Tenant Logical Isolation Active
          </Badge>
          <h1 className="text-4xl sm:text-6xl font-extrabold tracking-tight text-slate-900 dark:text-white">
            Enterprise Education Management Built on Infallible Architecture
          </h1>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            A unified SaaS platform for coaching centres, schools, and multi-branch colleges.
            Delivering strict PostgreSQL Row-Level Security, multi-branch scoping, and financial integrity.
          </p>
          <div className="flex justify-center gap-4 pt-4">
            <Link href="/alpha-institute">
              <Button size="lg" className="gap-2">
                Launch Alpha Institute Workspace <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
            <Link href="/beta-academy">
              <Button size="lg" variant="outline" className="gap-2">
                Launch Beta Academy Workspace
              </Button>
            </Link>
          </div>
        </section>

        {/* Core Architecture Cards */}
        <section className="max-w-6xl mx-auto px-6 pb-24 grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card className="shadow-sm border-slate-200 dark:border-slate-800">
            <CardHeader>
              <div className="h-10 w-10 rounded-md bg-blue-100 dark:bg-blue-900/40 text-primary flex items-center justify-center mb-2">
                <ShieldCheck className="h-5 w-5" />
              </div>
              <CardTitle className="text-lg">Row-Level Security (RLS)</CardTitle>
              <CardDescription>
                100% database-enforced multi-tenant isolation. Zero risk of cross-institute data leakage.
              </CardDescription>
            </CardHeader>
            <CardContent className="text-sm text-muted-foreground">
              Evaluated per session through Supabase JWT claims, ensuring queries never return unauthorized rows.
            </CardContent>
          </Card>

          <Card className="shadow-sm border-slate-200 dark:border-slate-800">
            <CardHeader>
              <div className="h-10 w-10 rounded-md bg-emerald-100 dark:bg-emerald-900/40 text-emerald-600 flex items-center justify-center mb-2">
                <Layers className="h-5 w-5" />
              </div>
              <CardTitle className="text-lg">Multi-Branch Hierarchy</CardTitle>
              <CardDescription>
                Native support for single institutes or complex multi-campus educational networks.
              </CardDescription>
            </CardHeader>
            <CardContent className="text-sm text-muted-foreground">
              Staff and student assignments are scoped to physical branches with centralized administrative oversight.
            </CardContent>
          </Card>

          <Card className="shadow-sm border-slate-200 dark:border-slate-800">
            <CardHeader>
              <div className="h-10 w-10 rounded-md bg-purple-100 dark:bg-purple-900/40 text-purple-600 flex items-center justify-center mb-2">
                <Users className="h-5 w-5" />
              </div>
              <CardTitle className="text-lg">Hierarchical RBAC</CardTitle>
              <CardDescription>
                Seven specialized institutional roles with granular branch permissions.
              </CardDescription>
            </CardHeader>
            <CardContent className="text-sm text-muted-foreground">
              Owner, Admin, Branch Manager, Teacher, Accountant, Receptionist, and unified Student/Parent credentials.
            </CardContent>
          </Card>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t py-6 text-center text-sm text-muted-foreground bg-white dark:bg-slate-900">
        InstituteOS Version 1.0.0 (Core Foundation) • Strict 5-Version Roadmap
      </footer>
    </div>
  );
}
