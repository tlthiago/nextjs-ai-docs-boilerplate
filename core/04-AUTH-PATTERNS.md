# 🔐 Authentication & Authorization Patterns

## **Overview**

This project uses **Better Auth** for authentication and authorization, providing enterprise-grade session management, audit trails, and role-based access control.

> 💡 **Why Better Auth**: Built for business applications with database sessions, audit capabilities, and full session control.

---

## 🔧 **Better Auth Setup**

### **Basic Configuration**

```typescript
// lib/auth.ts
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { prisma } from "./prisma";

export const auth = betterAuth({
  database: prismaAdapter(prisma, {
    provider: "postgresql",
  }),
  emailAndPassword: {
    enabled: true,
    requireEmailVerification: true,
  },
  session: {
    expiresIn: 60 * 60 * 24 * 7, // 7 days
    updateAge: 60 * 60 * 24, // 1 day
    cookieCache: {
      enabled: true,
      maxAge: 60 * 5, // 5 minutes
    },
  },
  user: {
    additionalFields: {
      role: {
        type: "string",
        defaultValue: "user",
      },
    },
  },
});

export type Session = typeof auth.$Infer.Session;
export type User = typeof auth.$Infer.User;
```

### **Database Schema (Prisma)**

```prisma
// prisma/schema.prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  role      String   @default("user")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  sessions Session[]
  accounts Account[]

  @@map("users")
}

model Session {
  id        String   @id @default(cuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("sessions")
}

model Account {
  id           String  @id @default(cuid())
  userId       String
  providerId   String
  providerUserId String
  accessToken  String?
  refreshToken String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([providerId, providerUserId])
  @@map("accounts")
}
```

---

## 🛡️ **Authentication Patterns**

### **Server-Side Authentication**

```typescript
// lib/auth-server.ts
import { auth } from "./auth";
import { headers } from "next/headers";

export async function getSession() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  return session;
}

export async function requireAuth() {
  const session = await getSession();

  if (!session) {
    throw new Error("Authentication required");
  }

  return session;
}

export async function requireRole(role: string) {
  const session = await requireAuth();

  if (session.user.role !== role && session.user.role !== "admin") {
    throw new Error("Insufficient permissions");
  }

  return session;
}
```

### **Client-Side Hook**

```typescript
// hooks/use-auth.ts
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { auth } from "@/lib/auth";

export function useAuth() {
  const queryClient = useQueryClient();

  const { data: session, isLoading } = useQuery({
    queryKey: ["session"],
    queryFn: () => auth.useSession(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  const signIn = useMutation({
    mutationFn: async (credentials: { email: string; password: string }) => {
      return auth.signIn.email(credentials);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["session"] });
    },
  });

  const signOut = useMutation({
    mutationFn: () => auth.signOut(),
    onSuccess: () => {
      queryClient.clear();
    },
  });

  return {
    user: session?.user ?? null,
    session,
    isLoading,
    isAuthenticated: !!session,
    signIn,
    signOut,
  };
}
```

---

## 🔒 **Route Protection Patterns**

### **API Route Protection**

```typescript
// lib/api-auth.ts
import { NextRequest } from "next/server";
import { auth } from "./auth";

export async function withAuth(
  handler: (req: NextRequest, session: Session) => Promise<Response>
) {
  return async (req: NextRequest) => {
    try {
      const session = await auth.api.getSession({
        headers: req.headers,
      });

      if (!session) {
        return new Response("Unauthorized", { status: 401 });
      }

      return handler(req, session);
    } catch (error) {
      return new Response("Authentication error", { status: 401 });
    }
  };
}

export async function withRole(
  role: string,
  handler: (req: NextRequest, session: Session) => Promise<Response>
) {
  return withAuth(async (req, session) => {
    if (session.user.role !== role && session.user.role !== "admin") {
      return new Response("Forbidden", { status: 403 });
    }

    return handler(req, session);
  });
}
```

### **Page Protection (Server Components)**

```typescript
// app/(private)/layout.tsx
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth-server";

export default async function PrivateLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getSession();

  if (!session) {
    redirect("/login");
  }

  return <>{children}</>;
}
```

### **Component-Level Protection**

```typescript
// components/auth-guard.tsx
"use client";

import { useAuth } from "@/hooks/use-auth";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

interface AuthGuardProps {
  children: React.ReactNode;
  requiredRole?: string;
  fallback?: React.ReactNode;
}

export function AuthGuard({
  children,
  requiredRole,
  fallback = <div>Access denied</div>,
}: AuthGuardProps) {
  const { user, isLoading, isAuthenticated } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push("/login");
    }
  }, [isLoading, isAuthenticated, router]);

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (!isAuthenticated) {
    return null;
  }

  if (requiredRole && user?.role !== requiredRole && user?.role !== "admin") {
    return fallback;
  }

  return <>{children}</>;
}
```

---

## 📝 **Authentication Forms**

### **Sign In Form**

```typescript
// components/auth/sign-in-form.tsx
"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";

const signInSchema = z.object({
  email: z.string().email("Invalid email address"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

type SignInFormData = z.infer<typeof signInSchema>;

export function SignInForm() {
  const { signIn } = useAuth();

  const form = useForm<SignInFormData>({
    resolver: zodResolver(signInSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  });

  const onSubmit = async (data: SignInFormData) => {
    try {
      await signIn.mutateAsync(data);
    } catch (error) {
      form.setError("root", {
        message: "Invalid email or password",
      });
    }
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="password"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Password</FormLabel>
              <FormControl>
                <Input type="password" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        {form.formState.errors.root && (
          <div className="text-sm text-red-600">
            {form.formState.errors.root.message}
          </div>
        )}

        <Button type="submit" className="w-full" disabled={signIn.isPending}>
          {signIn.isPending ? "Signing in..." : "Sign In"}
        </Button>
      </form>
    </Form>
  );
}
```

---

## 🎭 **Role-Based Access Control**

### **Role Definitions**

```typescript
// types/auth.ts
export const ROLES = {
  ADMIN: "admin",
  MANAGER: "manager",
  USER: "user",
} as const;

export type Role = (typeof ROLES)[keyof typeof ROLES];

export const ROLE_HIERARCHY = {
  [ROLES.ADMIN]: 3,
  [ROLES.MANAGER]: 2,
  [ROLES.USER]: 1,
} as const;

export function hasPermission(userRole: Role, requiredRole: Role): boolean {
  return ROLE_HIERARCHY[userRole] >= ROLE_HIERARCHY[requiredRole];
}
```

### **Permission Checking Hook**

```typescript
// hooks/use-permissions.ts
import { useAuth } from "./use-auth";
import { hasPermission, Role } from "@/types/auth";

export function usePermissions() {
  const { user } = useAuth();

  const checkPermission = (requiredRole: Role): boolean => {
    if (!user) return false;
    return hasPermission(user.role as Role, requiredRole);
  };

  const isAdmin = () => checkPermission("admin");
  const isManager = () => checkPermission("manager");

  return {
    checkPermission,
    isAdmin,
    isManager,
    userRole: user?.role as Role,
  };
}
```

---

## 🔍 **Audit Trail Patterns**

### **Session Tracking**

```typescript
// lib/audit.ts
import { prisma } from "./prisma";

export async function logUserAction(
  userId: string,
  action: string,
  resource?: string,
  metadata?: Record<string, any>
) {
  await prisma.auditLog.create({
    data: {
      userId,
      action,
      resource,
      metadata,
      timestamp: new Date(),
      ipAddress: "0.0.0.0", // Get from request
      userAgent: "unknown", // Get from request
    },
  });
}

// Usage in API routes
export async function withAudit(
  action: string,
  resource: string,
  handler: (req: NextRequest, session: Session) => Promise<Response>
) {
  return withAuth(async (req, session) => {
    const response = await handler(req, session);

    // Log successful actions
    if (response.ok) {
      await logUserAction(session.user.id, action, resource);
    }

    return response;
  });
}
```

---

## 🧪 **Testing Authentication**

### **Test Helper**

```typescript
// __tests__/helpers/auth.ts
import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";

export async function createTestUser(overrides: Partial<User> = {}) {
  const user = await prisma.user.create({
    data: {
      email: "test@example.com",
      name: "Test User",
      role: "user",
      ...overrides,
    },
  });

  return user;
}

export async function createTestSession(userId: string) {
  const session = await auth.createSession(userId);
  return session;
}

export function mockAuthHeaders(sessionToken: string) {
  return {
    cookie: `session=${sessionToken}`,
  };
}
```

### **API Route Test Example**

```typescript
// __tests__/api/resources.test.ts
import { describe, it, expect, beforeEach } from "@jest/globals";
import {
  createTestUser,
  createTestSession,
  mockAuthHeaders,
} from "../helpers/auth";

describe("/api/resources", () => {
  let testUser: User;
  let sessionToken: string;

  beforeEach(async () => {
    testUser = await createTestUser();
    const session = await createTestSession(testUser.id);
    sessionToken = session.token;
  });

  it("should require authentication", async () => {
    const response = await fetch("/api/resources");
    expect(response.status).toBe(401);
  });

  it("should allow authenticated requests", async () => {
    const response = await fetch("/api/resources", {
      headers: mockAuthHeaders(sessionToken),
    });
    expect(response.status).toBe(200);
  });
});
```

---

## 🔧 **Common Patterns**

### **Protecting API Routes**

```typescript
// app/api/resources/route.ts
import { withAuth } from "@/lib/api-auth";

export const GET = withAuth(async (req, session) => {
  // Access session.user here
  const resources = await getResourcesForUser(session.user.id);
  return Response.json(resources);
});

export const POST = withRole("manager", async (req, session) => {
  // Only managers and admins can create resources
  const data = await req.json();
  const resource = await createResource(data, session.user.id);
  return Response.json(resource);
});
```

### **Conditional UI Rendering**

```typescript
// components/resource-actions.tsx
"use client";

import { usePermissions } from "@/hooks/use-permissions";
import { Button } from "@/components/ui/button";

export function ResourceActions() {
  const { checkPermission } = usePermissions();

  return (
    <div className="flex gap-2">
      <Button variant="outline">View</Button>

      {checkPermission("manager") && <Button>Edit</Button>}

      {checkPermission("admin") && (
        <Button variant="destructive">Delete</Button>
      )}
    </div>
  );
}
```

---

## 📋 **Best Practices**

### **✅ Do:**

- Always validate sessions on the server side
- Use TypeScript for session and user types
- Implement proper error handling for auth failures
- Log authentication events for audit trails
- Use role-based permissions consistently
- Protect API routes with authentication middleware

### **❌ Don't:**

- Store sensitive data in client-side state
- Trust client-side role validation for security
- Use long-lived sessions without refresh
- Skip CSRF protection for state-changing operations
- Hardcode role checks throughout the app
- Forget to handle authentication errors gracefully

---

## 🔗 **Integration with Other Patterns**

- **API Patterns**: All API routes should use `withAuth()` or `withRole()`
- **Service Patterns**: Pass authenticated user context to services
- **Error Handling**: Use consistent error responses for auth failures
- **Testing**: Include authentication tests for all protected resources

This authentication system provides enterprise-grade security while maintaining developer productivity and AI agent compatibility.
