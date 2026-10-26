"use client";

import { useState } from "react";
import Link from "next/link";
import { Building2, Lock, Mail, ArrowRight, ShieldCheck } from "lucide-react";
import { Button } from "@/shared/ui/button";
import { Input } from "@/shared/ui/input";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/shared/ui/card";
import { Badge } from "@/shared/ui/badge";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [tenantSlug, setTenantSlug] = useState("alpha-institute");
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    // In V1 UI Shell prototype, navigate to target tenant dashboard
    setTimeout(() => {
      window.location.href = `/${tenantSlug}`;
    }, 600);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 dark:bg-slate-950 p-4">
      <Card className="w-full max-w-md shadow-lg border-slate-200 dark:border-slate-800">
        <CardHeader className="space-y-2 text-center pb-6">
          <div className="mx-auto h-12 w-12 rounded-xl bg-primary text-white flex items-center justify-center shadow-md">
            <Building2 className="h-7 w-7" />
          </div>
          <CardTitle className="text-2xl font-bold tracking-tight">
            Sign In to Institute<span className="text-primary">OS</span>
          </CardTitle>
          <CardDescription>
            Enter your credentials to access your institute&apos;s multi-branch portal.
          </CardDescription>
        </CardHeader>

        <form onSubmit={handleLogin}>
          <CardContent className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                Institute Workspace
              </label>
              <select
                value={tenantSlug}
                onChange={(e) => setTenantSlug(e.target.value)}
                className="w-full h-9 rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm focus:outline-none focus:ring-1 focus:ring-ring"
              >
                <option value="alpha-institute">Alpha Educational Foundation (alpha-institute)</option>
                <option value="beta-academy">Beta Learning Trust (beta-academy)</option>
              </select>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                Email Address
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  type="email"
                  placeholder="admin@institute.edu.in"
                  className="pl-9"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <div className="flex justify-between items-center">
                <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                  Password
                </label>
                <Link
                  href="/forgot-password"
                  className="text-xs text-primary hover:underline"
                >
                  Forgot password?
                </Link>
              </div>
              <div className="relative">
                <Lock className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  type="password"
                  placeholder="••••••••••••"
                  className="pl-9"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="rounded-lg bg-slate-100 dark:bg-slate-900 p-3 text-xs text-muted-foreground space-y-1 border">
              <div className="flex items-center gap-1.5 font-semibold text-slate-800 dark:text-slate-200">
                <ShieldCheck className="h-4 w-4 text-primary" />
                <span>Zero-Trust Authorization Active</span>
              </div>
              <p>
                Session authentication claims will bind database RLS policies to the selected workspace.
              </p>
            </div>
          </CardContent>

          <CardFooter className="flex flex-col gap-3">
            <Button type="submit" className="w-full gap-2" disabled={isLoading}>
              {isLoading ? "Signing in..." : "Access Workspace"}
              <ArrowRight className="h-4 w-4" />
            </Button>
            <div className="text-center text-xs text-muted-foreground">
              Need assistance? Contact your Institute Administrator.
            </div>
          </CardFooter>
        </form>
      </Card>
    </div>
  );
}
