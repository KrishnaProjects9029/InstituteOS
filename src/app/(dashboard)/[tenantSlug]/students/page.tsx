"use client";

import * as React from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/shared/ui/card";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";
import { Input } from "@/shared/ui/input";
import type { EnrolledStudentItem } from "@/shared/types/student";

// Synthetic initial mock data reflecting Phase 2.1 seed fixtures
const INITIAL_STUDENTS: EnrolledStudentItem[] = [
  {
    id: "11111111-7777-1111-1111-111111111101",
    admission_number: "ADM-2026-001",
    first_name: "Aarav",
    last_name: "Sharma",
    gender: "MALE",
    status: "ACTIVE",
    roll_number: 1,
    branch_name: "Main Campus (ALPHA-MAIN)",
    class_name: "Grade 10",
    division_name: "Section A",
    guardian_name: "Rajesh Sharma",
    guardian_phone: "+91 98765 43210",
    enrolled_at: "2026-06-01",
  },
  {
    id: "11111111-7777-1111-1111-111111111102",
    admission_number: "ADM-2026-002",
    first_name: "Priya",
    last_name: "Patel",
    gender: "FEMALE",
    status: "ACTIVE",
    roll_number: 2,
    branch_name: "Main Campus (ALPHA-MAIN)",
    class_name: "Grade 10",
    division_name: "Section A",
    guardian_name: "Mahesh Patel",
    guardian_phone: "+91 98765 43211",
    enrolled_at: "2026-06-01",
  },
  {
    id: "11111111-7777-1111-1111-111111111103",
    admission_number: "ADM-2026-003",
    first_name: "Rohan",
    last_name: "Joshi",
    gender: "MALE",
    status: "ACTIVE",
    roll_number: 1,
    branch_name: "Main Campus (ALPHA-MAIN)",
    class_name: "Grade 10",
    division_name: "Section B",
    guardian_name: "Sunil Joshi",
    guardian_phone: "+91 98765 43212",
    enrolled_at: "2026-06-02",
  },
  {
    id: "11111111-7777-1111-1111-111111111104",
    admission_number: "ADM-2026-004",
    first_name: "Ananya",
    last_name: "Deshmukh",
    gender: "FEMALE",
    status: "ACTIVE",
    roll_number: 25,
    branch_name: "Main Campus (ALPHA-MAIN)",
    class_name: "Grade 10",
    division_name: "Section A",
    guardian_name: "Kiran Deshmukh",
    guardian_phone: "+91 98765 43213",
    enrolled_at: "2026-06-05",
  },
];

export default function StudentsDirectoryPage() {
  const params = useParams();
  const tenantSlug = typeof params.tenantSlug === "string" ? params.tenantSlug : "alpha-institute";
  const [searchQuery, setSearchQuery] = React.useState("");
  const [selectedDivision, setSelectedDivision] = React.useState("ALL");

  const filteredStudents = INITIAL_STUDENTS.filter((student) => {
    const matchesSearch =
      student.first_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      student.last_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      student.admission_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
      student.guardian_name.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesDivision =
      selectedDivision === "ALL" || student.division_name === selectedDivision;

    return matchesSearch && matchesDivision;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Student Admissions & Directory</h1>
          <p className="text-muted-foreground">
            Manage student lifecycle, enrollment registries, and automatic sequential roll numbers.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link href={`/${tenantSlug}/students/new`}>
            <Button className="bg-primary hover:bg-primary/90 text-primary-foreground">
              + New Student Admission
            </Button>
          </Link>
        </div>
      </div>

      {/* Summary KPI Badges */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription className="text-xs uppercase font-medium">Enrolled Students</CardDescription>
            <CardTitle className="text-2xl font-bold">{INITIAL_STUDENTS.length}</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-xs text-muted-foreground">Active in Academic Year 2026–2027</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription className="text-xs uppercase font-medium">Active Divisions</CardDescription>
            <CardTitle className="text-2xl font-bold">2</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-xs text-muted-foreground">Section A (3) &bull; Section B (1)</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription className="text-xs uppercase font-medium">Roll Number Mode</CardDescription>
            <CardTitle className="text-xl font-bold text-emerald-600 dark:text-emerald-400">
              Auto-Sequential
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-xs text-muted-foreground">Concurrency-safe division locking</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription className="text-xs uppercase font-medium">Audited Overrides</CardDescription>
            <CardTitle className="text-2xl font-bold">1</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-xs text-muted-foreground">Manual roll #25 logged in audit_logs</p>
          </CardContent>
        </Card>
      </div>

      {/* Filter and Search Bar */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="w-full sm:w-80">
              <Input
                placeholder="Search by name, admission #, or guardian..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-medium text-muted-foreground">Division:</span>
              <Button
                variant={selectedDivision === "ALL" ? "default" : "outline"}
                size="sm"
                onClick={() => setSelectedDivision("ALL")}
              >
                All
              </Button>
              <Button
                variant={selectedDivision === "Section A" ? "default" : "outline"}
                size="sm"
                onClick={() => setSelectedDivision("Section A")}
              >
                Section A
              </Button>
              <Button
                variant={selectedDivision === "Section B" ? "default" : "outline"}
                size="sm"
                onClick={() => setSelectedDivision("Section B")}
              >
                Section B
              </Button>
            </div>
          </div>
        </CardHeader>

        <CardContent>
          <div className="overflow-x-auto rounded-md border border-border">
            <table className="w-full text-left text-sm">
              <thead className="bg-muted text-xs uppercase text-muted-foreground">
                <tr>
                  <th className="px-4 py-3 font-semibold">Adm #</th>
                  <th className="px-4 py-3 font-semibold">Roll #</th>
                  <th className="px-4 py-3 font-semibold">Student Name</th>
                  <th className="px-4 py-3 font-semibold">Class & Division</th>
                  <th className="px-4 py-3 font-semibold">Branch</th>
                  <th className="px-4 py-3 font-semibold">Guardian Contact</th>
                  <th className="px-4 py-3 font-semibold">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filteredStudents.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-4 py-8 text-center text-muted-foreground">
                      No students found matching current filters.
                    </td>
                  </tr>
                ) : (
                  filteredStudents.map((s) => (
                    <tr key={s.id} className="hover:bg-muted/50 transition-colors">
                      <td className="px-4 py-3 font-mono font-medium text-xs text-primary">
                        {s.admission_number}
                      </td>
                      <td className="px-4 py-3 font-bold text-center">
                        <Badge variant="outline" className="font-mono px-2 py-0.5">
                          #{s.roll_number}
                        </Badge>
                      </td>
                      <td className="px-4 py-3">
                        <div className="font-medium text-foreground">
                          {s.first_name} {s.last_name}
                        </div>
                        <div className="text-xs text-muted-foreground capitalize">
                          {s.gender.toLowerCase()} &bull; Enrolled {s.enrolled_at}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="font-medium">{s.class_name}</div>
                        <div className="text-xs text-muted-foreground">{s.division_name}</div>
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground">
                        {s.branch_name}
                      </td>
                      <td className="px-4 py-3">
                        <div className="text-xs font-medium">{s.guardian_name}</div>
                        <div className="text-xs text-muted-foreground font-mono">{s.guardian_phone}</div>
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant="success">{s.status}</Badge>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
