# 🔧 Better Auth Complete Setup

## **Overview**

Complete Better Auth configuration with admin plugin, email verification, domain validation, and enterprise-grade features for Next.js applications.

---

## 🚀 **Production Configuration**

### **Core Auth Setup**

```typescript
// lib/auth.ts
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { APIError } from "better-auth/api";
import {
  admin as adminPlugin,
  createAuthMiddleware,
} from "better-auth/plugins";

import { UserRole } from "@/generated/prisma";
import { ac, roles } from "@/lib/permissions";
import prisma from "@/lib/prisma";

import { sendForgotPassword } from "./email/send-forgot-password";
import { sendVerificationEmail } from "./email/send-verification";
import { getValidDomains, normalizeName } from "./utils";

export const auth = betterAuth({
  database: prismaAdapter(prisma, {
    provider: "postgresql",
  }),
  emailAndPassword: {
    enabled: true,
    minPasswordLength: 8,
    autoSignIn: false,
    requireEmailVerification: true,
    sendResetPassword: async ({ user, url }) => {
      await sendForgotPassword({
        to: user.email,
        name: user.name,
        resetUrl: url,
      });
    },
  },
  emailVerification: {
    sendOnSignUp: true,
    autoSignInAfterVerification: true,
    sendVerificationEmail: async ({ user, url }) => {
      const link = new URL(url);
      link.searchParams.set("callbackURL", "/auth/verify");

      await sendVerificationEmail({
        to: user.email,
        name: user.name,
        verifyUrl: String(link),
      });
    },
  },
  hooks: {
    before: createAuthMiddleware(async (ctx) => {
      if (ctx.path === "/sign-up/email") {
        const email = String(ctx.body.email);
        const domain = email.split("@")[1];

        const VALID_DOMAINS = getValidDomains();
        if (!VALID_DOMAINS.includes(domain)) {
          throw new APIError("BAD_REQUEST", {
            message: "Invalid domain. Please use a valid email address",
          });
        }

        const name = normalizeName(ctx.body.name);

        return {
          context: {
            ...ctx,
            body: {
              ...ctx.body,
              name,
            },
          },
        };
      }
    }),
  },
  databaseHooks: {
    user: {
      create: {
        before: async (user) => {
          const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "";

          if (ADMIN_EMAIL === user.email) {
            return {
              data: { ...user, role: UserRole.ADMIN, emailVerified: true },
            };
          }

          return { data: user };
        },
      },
    },
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
      ac,
      roles,
      defaultRole: UserRole.USER,
      adminRoles: UserRole.ADMIN,
    }),
  ],
  advanced: {
    database: {
      generateId: false,
    },
  },
});

export type Session = typeof auth.$Infer.Session;
export type User = typeof auth.$Infer.User;
```

---

## 🏗️ **Database Schema**

### **Prisma Schema with Better Auth**

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

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

model Verification {
  id        String   @id @default(cuid())
  userId    String
  type      String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())

  @@map("verifications")
}
```

---

## 🛠️ **Utility Functions**

### **Domain Validation**

```typescript
// lib/auth/utils.ts
export function getValidDomains(): string[] {
  const domains = process.env.VALID_EMAIL_DOMAINS || "";
  
  if (!domains) {
    // Allow common business domains by default
    return [
      "gmail.com",
      "outlook.com", 
      "company.com" // Replace with your company domain
    ];
  }
  
  return domains.split(",").map(domain => domain.trim());
}

export function normalizeName(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/\b\w/g, l => l.toUpperCase()); // Title case
}

export function isValidBusinessEmail(email: string): boolean {
  const domain = email.split("@")[1];
  const validDomains = getValidDomains();
  return validDomains.includes(domain);
}
```

### **Environment Configuration**

```bash
# .env.local
DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
ADMIN_EMAIL="admin@company.com"
VALID_EMAIL_DOMAINS="company.com,partner.com,contractor.com"

# Email configuration (see email-verification.md)
SMTP_HOST="smtp.example.com"
SMTP_PORT="587"
SMTP_USER="noreply@company.com"
SMTP_PASS="your-password"
SMTP_FROM="noreply@company.com"
```

---

## 🔌 **Server-Side Integration**

### **Auth Server Utilities**

```typescript
// lib/auth-server.ts
import { auth } from "./auth";
import { headers } from "next/headers";
import { UserRole } from "@/generated/prisma";

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

---

## 🎯 **Client-Side Integration**

### **Auth Hook with Admin Features**

```typescript
// hooks/use-auth.ts
"use client";

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

## 🔒 **API Route Protection**

### **Advanced Auth Middleware**

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

---

## 🧪 **Testing Setup**

### **Test Utilities**

```typescript
// __tests__/helpers/auth.ts
import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { UserRole } from "@/generated/prisma";

export async function createTestUser(overrides: Partial<User> = {}) {
  const user = await prisma.user.create({
    data: {
      email: "test@company.com",
      name: "Test User",
      role: UserRole.USER,
      active: true,
      emailVerified: true,
      ...overrides,
    },
  });

  return user;
}

export async function createTestAdmin() {
  return createTestUser({
    email: "admin@company.com",
    name: "Test Admin",
    role: UserRole.ADMIN,
  });
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

export async function setupTestAuth() {
  const user = await createTestUser();
  const session = await createTestSession(user.id);
  const headers = mockAuthHeaders(session.token);
  
  return { user, session, headers };
}
```

---

## 📋 **Best Practices**

### **✅ Do:**

- Always validate email domains in production
- Use environment variables for admin email configuration
- Implement proper error handling for auth failures
- Verify email before allowing sign-in
- Check user active status on protected routes
- Use TypeScript for type safety with roles and sessions

### **❌ Don't:**

- Hardcode valid email domains in the source code
- Skip email verification in production
- Allow inactive users to access protected resources
- Forget to handle authentication errors gracefully
- Store sensitive configuration in source code

---

## 🔗 **Related Documentation**

- **[Permission System](./permission-system.md)** - Advanced role-based access control
- **[Email Verification](./email-verification.md)** - Email verification implementation
- **[Reset Password](./reset-password.md)** - Password reset implementation  
- **[Admin Plugin](./admin-plugin-patterns.md)** - Admin plugin configuration and usage

This setup provides enterprise-grade authentication with domain validation, email verification, and comprehensive role management while maintaining developer productivity and AI agent compatibility.
