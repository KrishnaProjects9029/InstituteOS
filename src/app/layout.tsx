import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "InstituteOS — Enterprise Education Management SaaS",
  description:
    "Multi-tenant academic operations, attendance, fee accounting, and compliance platform.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-background text-foreground antialiased">
        {children}
      </body>
    </html>
  );
}
