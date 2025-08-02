## 🔧 **API Middleware Patterns**

rate limit via better auth https://www.better-auth.com/docs/concepts/rate-limit
cors e headers security https://nextjs.org/docs/app/api-reference/config/next-config-js/headers#options

## 🔒 **Authentication and Authorization**

### **Auth Middleware**

```typescript
// middleware.ts - Protects all /api/v1/* routes
import { auth } from "@/lib/auth";

export async function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  // Skip auth routes
  if (pathname.startsWith("/api/v1/auth/")) {
    return NextResponse.next();
  }

  // Check authentication for other routes
  if (pathname.startsWith("/api/v1/")) {
    const session = await auth.api.getSession({
      headers: request.headers,
    });

    if (!session) {
      return NextResponse.json(
        { error: { message: "Unauthorized.", code: "UNAUTHORIZED" } },
        { status: 401 },
      );
    }
  }

  return NextResponse.next();
}
```

### **Global API Middleware Stack**

```typescript
// middleware.ts
import { NextRequest, NextResponse } from "next/server";

export async function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  // Skip middleware for auth routes
  if (pathname.startsWith("/api/v1/auth/")) {
    return NextResponse.next();
  }

  // Apply to all API routes
  if (pathname.startsWith("/api/v1/")) {
    // 1. Authentication check
    const authResult = await checkAuthentication(request);
    if (!authResult.success) {
      return authResult.response;
    }

    // 2. Rate limiting
    const rateLimitResult = await checkRateLimit(request);
    if (!rateLimitResult.success) {
      return rateLimitResult.response;
    }

    // 3. Request logging
    logRequest(request);

    // Add request ID for tracing
    const response = NextResponse.next();
    response.headers.set("X-Request-ID", crypto.randomUUID());
    return response;
  }

  return NextResponse.next();
}

async function checkAuthentication(request: NextRequest) {
  // Implementation details in auth section
}

async function checkRateLimit(request: NextRequest) {
  // Implementation details in rate limiting section
}

function logRequest(request: NextRequest) {
  console.log({
    timestamp: new Date().toISOString(),
    method: request.method,
    url: request.url,
    userAgent: request.headers.get("user-agent"),
    ip: request.ip,
  });
}
```

### **Route-Level Middleware Composition**

```typescript
// lib/api/with-middleware.ts
type ApiHandler = (request: Request, context?: any) => Promise<NextResponse>;

export function withMiddleware(...middlewares: Function[]) {
  return function (handler: ApiHandler): ApiHandler {
    return async (request: Request, context?: any) => {
      // Apply middlewares in sequence
      for (const middleware of middlewares) {
        const result = await middleware(request, context);
        if (result && result instanceof NextResponse) {
          return result; // Middleware returned early response
        }
      }

      // Execute main handler
      return await handler(request, context);
    };
  };
}

// Usage example
export const GET = withMiddleware(
  withAuth,
  withRateLimit(apiRateLimiter),
  withAnalytics,
)(async (request: Request) => {
  // Main handler logic
  return NextResponse.json({ data: "success" });
});
```
