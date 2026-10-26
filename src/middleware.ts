import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const url = request.nextUrl.clone();
  const hostname = request.headers.get("host") || "";

  // Skip static assets and internal API health endpoints
  if (
    url.pathname.startsWith("/_next") ||
    url.pathname.startsWith("/api/health") ||
    url.pathname.includes(".")
  ) {
    return NextResponse.next();
  }

  // Multi-Tenant Subdomain & Path Parsing
  // Example: "alpha.instituteos.com" or "localhost:3000/[tenantSlug]"
  const rootDomain = process.env.NEXT_PUBLIC_ROOT_DOMAIN || "localhost:3000";
  const isSubdomain =
    hostname.includes(".") &&
    !hostname.startsWith("www.") &&
    hostname !== rootDomain &&
    !hostname.startsWith("localhost");

  let tenantSlug = "";

  if (isSubdomain) {
    tenantSlug = hostname.replace(`.${rootDomain}`, "").toLowerCase();
  } else {
    // Check if path is prefixed with a tenant slug, e.g. /alpha-institute/...
    const segments = url.pathname.split("/").filter(Boolean);
    if (segments.length > 0 && segments[0] !== "login" && segments[0] !== "api") {
      tenantSlug = segments[0];
    }
  }

  // Clone headers and attach resolved tenant slug context
  const requestHeaders = new Headers(request.headers);
  if (tenantSlug) {
    requestHeaders.set("x-tenant-slug", tenantSlug);
  }

  return NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  });
}

export const config = {
  matcher: ["/((?!api/health|_next/static|_next/image|favicon.ico).*)"],
};
