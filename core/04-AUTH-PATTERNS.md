# 🔐 Authentication & Authorization Patterns

## **Overview**

This project uses **Better Auth** with admin plugin for enterprise-grade authentication, providing session management, role-based access control, email verification, and comprehensive user management.

> 💡 **Why Better Auth**: Built for business applications with database sessions, admin capabilities, and full session control.

---

## � **Quick Start**

### **Core Authentication Setup**

```typescript
// lib/auth.ts
import { betterAuth } from "better-auth";
import { prismaAdapter } fr## 📚 Detailed Documentation

For complete implementation details, see the modular authentication documentation:

- **[Better Auth Setup](./auth/better-auth-setup.md)** - Complete configuration with admin plugin
- **[Permission System](./auth/permission-system.md)** - Advanced role-based access control
- **[Email Verification](./auth/email-verification.md)** - Email verification implementation
- **[Reset Password](./auth/reset-password.md)** - Password reset patterns
- **[Admin Plugin](./auth/admin-plugin-patterns.md)** - Admin user managementr-auth/adapters/prisma";
import { admin as adminPlugin } from "better-auth/plugins";
import { UserRole } from "@/generated/prisma";
import { ac, roles } from "@/lib/permissions";
import prisma from "@/lib/prisma";

export const auth = betterAuth({
  database: prismaAdapter(prisma, {
    provider: "postgresql",
  }),
  emailAndPassword: {
    enabled: true,
    minPasswordLength: 8,
    requireEmailVerification: true,
  },
  user: {
    additionalFields: {
      active: {
        type: "boolean",
        input: false,
      },
      role: {
        type: ["ADMIN", "USER"] as Array<UserRole>,
        input: false,
      },
    },
  },
  plugins: [
    adminPlugin({
      ac, // Access control
      roles, // Role definitions
      defaultRole: UserRole.USER,
      adminRoles: UserRole.ADMIN,
    }),
  ],
});

export type Session = typeof auth.$Infer.Session;
export type User = typeof auth.$Infer.User;
```

### **Database Schema (Prisma)**

```prisma
// prisma/schema.prisma
enum UserRole {
  ADMIN
  USER
}

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  name          String
  role          UserRole  @default(USER)
  active        Boolean   @default(true)
  emailVerified Boolean   @default(false)
  image         String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  // Better Auth relations
  sessions Session[]
  accounts Account[]

  // App-specific relations
  createdResources Resource[] @relation("CreatedByUser")
  updatedResources Resource[] @relation("UpdatedByUser")

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
  id                String  @id @default(cuid())
  userId            String
  providerId        String
  providerUserId    String
  accessToken       String?
  refreshToken      String?
  accessTokenExpiry DateTime?
  scope             String?

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

export async function requireRole(role: UserRole) {
  const session = await requireAuth();

  if (session.user.role !== role && session.user.role !== UserRole.ADMIN) {
    throw new Error("Insufficient permissions");
  }

  return session;
}

export async function requireActiveUser() {
  const session = await requireAuth();

  if (!session.user.active) {
    throw new Error("Account is inactive");
  }

  return session;
}
```

### **Client-Side Hook**

```typescript
// hooks/use-auth.ts
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { auth } from "@/lib/auth";
import { UserRole } from "@/generated/prisma";

export function useAuth() {
  const queryClient = useQueryClient();

  const { data: session, isLoading } = useQuery({
    queryKey: ["session"],
    queryFn: () => auth.useSession(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  const signIn = useMutation({
    mutationFn: async (credentials: { email: string; password: string }) => {
      const result = await auth.signIn.email(credentials);

      if (!result.data?.user.emailVerified) {
        throw new Error("Please verify your email before signing in");
      }

      if (!result.data?.user.active) {
        throw new Error("Your account is inactive. Contact administrator");
      }

      return result;
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

  const user = session?.user;

  return {
    user,
    session,
    isLoading,
    isAuthenticated: !!session,
    isAdmin: user?.role === UserRole.ADMIN,
    isActive: user?.active ?? false,
    isEmailVerified: user?.emailVerified ?? false,
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
import { UserRole } from "@/generated/prisma";

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

      if (!session.user.active) {
        return new Response("Account inactive", { status: 403 });
      }

      if (!session.user.emailVerified) {
        return new Response("Email not verified", { status: 403 });
      }

      return handler(req, session);
    } catch (error) {
      return new Response("Authentication error", { status: 401 });
    }
  };
}

export async function withRole(
  role: UserRole,
  handler: (req: NextRequest, session: Session) => Promise<Response>
) {
  return withAuth(async (req, session) => {
    if (session.user.role !== role && session.user.role !== UserRole.ADMIN) {
      return new Response("Insufficient permissions", { status: 403 });
    }

    return handler(req, session);
  });
}

export async function withAdmin(
  handler: (req: NextRequest, session: Session) => Promise<Response>
) {
  return withRole(UserRole.ADMIN, handler);
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

  if (
    requiredRole &&
    user?.role !== requiredRole &&
    user?.role !== UserRole.ADMIN
  ) {
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
import { UserRole } from "@/generated/prisma";

export const ROLE_HIERARCHY = {
  [UserRole.ADMIN]: 2,
  [UserRole.USER]: 1,
} as const;

export function hasPermission(
  userRole: UserRole,
  requiredRole: UserRole
): boolean {
  return ROLE_HIERARCHY[userRole] >= ROLE_HIERARCHY[requiredRole];
}

export function isAdmin(userRole: UserRole): boolean {
  return userRole === UserRole.ADMIN;
}
```

### **Permission Checking Hook**

```typescript
// hooks/use-permissions.ts
import { useAuth } from "./use-auth";
import { hasPermission, isAdmin, UserRole } from "@/types/auth";

export function usePermissions() {
  const { user } = useAuth();

  const checkPermission = (requiredRole: UserRole): boolean => {
    if (!user) return false;
    return hasPermission(user.role as UserRole, requiredRole);
  };

  return {
    checkPermission,
    isAdmin: () => (user ? isAdmin(user.role as UserRole) : false),
    userRole: user?.role as UserRole,
  };
}
```

---

## � **Common Patterns**

### **Protecting API Routes**

```typescript
// app/api/resources/route.ts
import { withAuth, withAdmin } from "@/lib/api-auth";

export const GET = withAuth(async (req, session) => {
  // Access session.user here
  const resources = await getResourcesForUser(session.user.id);
  return Response.json(resources);
});

export const POST = withAdmin(async (req, session) => {
  // Only admins can create resources
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
import { UserRole } from "@/generated/prisma";
import { Button } from "@/components/ui/button";

export function ResourceActions() {
  const { checkPermission, isAdmin } = usePermissions();

  return (
    <div className="flex gap-2">
      <Button variant="outline">View</Button>

      {checkPermission(UserRole.USER) && <Button>Edit</Button>}

      {isAdmin() && <Button variant="destructive">Delete</Button>}
    </div>
  );
}
```

---

## 📚 **Detailed Documentation**

For comprehensive implementation guides, see:

- **[Better Auth Setup](./auth/better-auth-setup.md)** - Complete configuration with admin plugin
- **[Permission System](./auth/permission-system.md)** - Advanced role-based access control
- **[Email Verification](./auth/email-verification.md)** - Email verification implementation
- **[Reset Password](./auth/reset-password.md)** - Password reset patterns
- **[Admin Plugin](./auth/admin-plugin-patterns.md)** - Admin user management

---

## 🚀 **Future Enhancements**

- **[Audit Patterns](./improvements/AUDIT-PATTERNS.md)** - Comprehensive audit logging (Phase 2)

---

## 📋 **Best Practices**

### **✅ Do:**

- Always validate sessions on the server side
- Use TypeScript for session and user types
- Implement proper error handling for auth failures
- Check user active status and email verification
- Use role-based permissions consistently
- Protect API routes with authentication middleware
- Use environment variables for email configuration
- Implement rate limiting for sensitive operations

### **❌ Don't:**

- Store sensitive data in client-side state
- Trust client-side role validation for security
- Skip email verification in production
- Allow inactive users to access protected resources
- Hardcode role checks throughout the app
- Forget to handle authentication errors gracefully
- Skip domain validation for business applications

---

## 🔗 **Integration with Other Patterns**

- **[API Patterns](./06-API-PATTERNS.md)** - All API routes should use `withAuth()` or `withRole()`
- **[Service Patterns](./05-SERVICE-PATTERNS.md)** - Pass authenticated user context to services
- **[Error Handling](./09-ERROR-HANDLING.md)** - Use consistent error responses for auth failures
- **[Component Patterns](./07-COMPONENT-PATTERNS.md)** - Implement auth-aware components

This authentication system provides enterprise-grade security with admin capabilities while maintaining developer productivity and AI agent compatibility.
