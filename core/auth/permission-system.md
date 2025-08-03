# 🎭 Permission System Patterns

## **Overview**

Advanced role-based access control (RBAC) using Better Auth's admin plugin with granular permissions for enterprise applications.

---

## 🏗️ **Permission Architecture**

### **Access Control Setup**

```typescript
// lib/permissions.ts
import { AccessControl } from "accesscontrol";
import { UserRole } from "@/generated/prisma";

// Define available resources
export const RESOURCES = {
  RESOURCE: "resource",
  CATEGORY: "category", 
  USER: "user",
  ADMIN: "admin",
  PROFILE: "profile",
} as const;

// Define available actions
export const ACTIONS = {
  CREATE: "create",
  READ: "read", 
  UPDATE: "update",
  DELETE: "delete",
  LIST: "list",
  MANAGE: "manage", // Full control
} as const;

// Initialize AccessControl
export const ac = new AccessControl();

// Define role hierarchy and permissions
export const roles = {
  [UserRole.USER]: ac
    .grant(UserRole.USER)
    .readOwn(RESOURCES.RESOURCE)
    .updateOwn(RESOURCES.RESOURCE)
    .readOwn(RESOURCES.PROFILE)
    .updateOwn(RESOURCES.PROFILE),

  [UserRole.ADMIN]: ac
    .grant(UserRole.ADMIN)
    .extend(UserRole.USER) // Inherit USER permissions
    .createAny(RESOURCES.RESOURCE)
    .readAny(RESOURCES.RESOURCE)
    .updateAny(RESOURCES.RESOURCE)
    .deleteAny(RESOURCES.RESOURCE)
    .createAny(RESOURCES.CATEGORY)
    .readAny(RESOURCES.CATEGORY)
    .updateAny(RESOURCES.CATEGORY)
    .deleteAny(RESOURCES.CATEGORY)
    .createAny(RESOURCES.USER)
    .readAny(RESOURCES.USER)
    .updateAny(RESOURCES.USER)
    .deleteAny(RESOURCES.USER)
    .readAny(RESOURCES.PROFILE)
    .updateAny(RESOURCES.PROFILE),
};

export type Resource = (typeof RESOURCES)[keyof typeof RESOURCES];
export type Action = (typeof ACTIONS)[keyof typeof ACTIONS];
```

---

## 🔐 **Permission Checking**

### **Server-Side Permission Utils**

```typescript
// lib/auth-permissions.ts
import { ac, Resource, Action } from "./permissions";
import { getSession } from "./auth-server";
import { UserRole } from "@/generated/prisma";

export async function checkPermission(
  resource: Resource,
  action: Action,
  ownerId?: string
) {
  const session = await getSession();
  
  if (!session) {
    return false;
  }

  const { user } = session;
  const userRole = user.role as UserRole;

  // Check if user can perform action on any resource
  const anyPermission = ac.can(userRole)[action + "Any"](resource);
  if (anyPermission.granted) {
    return true;
  }

  // Check if user can perform action on own resource
  if (ownerId && ownerId === user.id) {
    const ownPermission = ac.can(userRole)[action + "Own"](resource);
    return ownPermission.granted;
  }

  return false;
}

export async function requirePermission(
  resource: Resource,
  action: Action,
  ownerId?: string
) {
  const hasPermission = await checkPermission(resource, action, ownerId);
  
  if (!hasPermission) {
    throw new Error(
      `Insufficient permissions: Cannot ${action} ${resource}`
    );
  }

  return true;
}

export async function getFilteredData<T extends { createdById: string }>(
  data: T[],
  resource: Resource
): Promise<T[]> {
  const session = await getSession();
  
  if (!session) {
    return [];
  }

  const userRole = session.user.role as UserRole;
  const canReadAny = ac.can(userRole).readAny(resource).granted;

  if (canReadAny) {
    return data; // Admin can see all
  }

  // Regular users can only see their own data
  return data.filter(item => item.createdById === session.user.id);
}
```

### **Client-Side Permission Hook**

```typescript
// hooks/use-permissions.ts
"use client";

import { useAuth } from "./use-auth";
import { ac, Resource, Action } from "@/lib/permissions";
import { UserRole } from "@/generated/prisma";

export function usePermissions() {
  const { user, isAuthenticated } = useAuth();

  const checkPermission = (
    resource: Resource,
    action: Action,
    ownerId?: string
  ): boolean => {
    if (!isAuthenticated || !user) {
      return false;
    }

    const userRole = user.role as UserRole;

    // Check if user can perform action on any resource
    const anyPermission = ac.can(userRole)[action + "Any"](resource);
    if (anyPermission.granted) {
      return true;
    }

    // Check if user can perform action on own resource
    if (ownerId && ownerId === user.id) {
      const ownPermission = ac.can(userRole)[action + "Own"](resource);
      return ownPermission.granted;
    }

    return false;
  };

  const can = {
    create: (resource: Resource) => checkPermission(resource, "create"),
    read: (resource: Resource, ownerId?: string) => 
      checkPermission(resource, "read", ownerId),
    update: (resource: Resource, ownerId?: string) => 
      checkPermission(resource, "update", ownerId),
    delete: (resource: Resource, ownerId?: string) => 
      checkPermission(resource, "delete", ownerId),
    list: (resource: Resource) => checkPermission(resource, "list"),
    manage: (resource: Resource) => checkPermission(resource, "manage"),
  };

  const is = {
    admin: () => user?.role === UserRole.ADMIN,
    user: () => user?.role === UserRole.USER,
  };

  return {
    can,
    is,
    checkPermission,
    userRole: user?.role as UserRole,
  };
}
```

---

## 🛡️ **API Route Protection**

### **Permission-Based Middleware**

```typescript
// lib/api-permissions.ts
import { NextRequest } from "next/server";
import { withAuth } from "./api-auth";
import { checkPermission, Resource, Action } from "./auth-permissions";

export function withPermission(
  resource: Resource,
  action: Action,
  handler: (req: NextRequest, session: Session) => Promise<Response>
) {
  return withAuth(async (req, session) => {
    try {
      // Extract ownerId from request if checking own resources
      let ownerId: string | undefined;
      
      if (action === "update" || action === "delete") {
        const url = new URL(req.url);
        const id = url.pathname.split("/").pop();
        
        // You might need to fetch the resource to get ownerId
        // This is a simplified example
        if (resource === "resource") {
          const resourceData = await prisma.resource.findUnique({
            where: { id },
            select: { createdById: true },
          });
          ownerId = resourceData?.createdById;
        }
      }

      const hasPermission = await checkPermission(resource, action, ownerId);
      
      if (!hasPermission) {
        return new Response(
          `Insufficient permissions: Cannot ${action} ${resource}`, 
          { status: 403 }
        );
      }

      return handler(req, session);
    } catch (error) {
      return new Response("Permission check failed", { status: 500 });
    }
  });
}

// Convenience functions for common patterns
export function withCreatePermission(resource: Resource) {
  return (handler: (req: NextRequest, session: Session) => Promise<Response>) =>
    withPermission(resource, "create", handler);
}

export function withReadPermission(resource: Resource) {
  return (handler: (req: NextRequest, session: Session) => Promise<Response>) =>
    withPermission(resource, "read", handler);
}

export function withUpdatePermission(resource: Resource) {
  return (handler: (req: NextRequest, session: Session) => Promise<Response>) =>
    withPermission(resource, "update", handler);
}

export function withDeletePermission(resource: Resource) {
  return (handler: (req: NextRequest, session: Session) => Promise<Response>) =>
    withPermission(resource, "delete", handler);
}
```

---

## 📊 **Usage Examples**

### **API Route Examples**

```typescript
// app/api/resources/route.ts
import { withPermission } from "@/lib/api-permissions";
import { RESOURCES } from "@/lib/permissions";

export const GET = withPermission(
  RESOURCES.RESOURCE, 
  "list", 
  async (req, session) => {
    const resources = await getFilteredData(
      await prisma.resource.findMany({
        include: { createdBy: true }
      }),
      RESOURCES.RESOURCE
    );
    
    return Response.json(resources);
  }
);

export const POST = withPermission(
  RESOURCES.RESOURCE,
  "create",
  async (req, session) => {
    const data = await req.json();
    
    const resource = await prisma.resource.create({
      data: {
        ...data,
        createdById: session.user.id,
      },
    });
    
    return Response.json(resource);
  }
);
```

```typescript
// app/api/resources/[id]/route.ts
import { withUpdatePermission, withDeletePermission } from "@/lib/api-permissions";
import { RESOURCES } from "@/lib/permissions";

export const PUT = withUpdatePermission(RESOURCES.RESOURCE);
export const DELETE = withDeletePermission(RESOURCES.RESOURCE);
```

### **Component Examples**

```typescript
// components/resource-actions.tsx
"use client";

import { usePermissions } from "@/hooks/use-permissions";
import { RESOURCES } from "@/lib/permissions";
import { Button } from "@/components/ui/button";

interface ResourceActionsProps {
  resource: {
    id: string;
    createdById: string;
  };
}

export function ResourceActions({ resource }: ResourceActionsProps) {
  const { can } = usePermissions();

  return (
    <div className="flex gap-2">
      {can.read(RESOURCES.RESOURCE, resource.createdById) && (
        <Button variant="outline">View</Button>
      )}

      {can.update(RESOURCES.RESOURCE, resource.createdById) && (
        <Button>Edit</Button>
      )}

      {can.delete(RESOURCES.RESOURCE, resource.createdById) && (
        <Button variant="destructive">Delete</Button>
      )}
    </div>
  );
}
```

### **Page Protection Example**

```typescript
// components/permission-guard.tsx
"use client";

import { usePermissions } from "@/hooks/use-permissions";
import { Resource, Action } from "@/lib/permissions";

interface PermissionGuardProps {
  children: React.ReactNode;
  resource: Resource;
  action: Action;
  ownerId?: string;
  fallback?: React.ReactNode;
}

export function PermissionGuard({
  children,
  resource,
  action,
  ownerId,
  fallback = <div>Access denied</div>,
}: PermissionGuardProps) {
  const { checkPermission } = usePermissions();

  if (!checkPermission(resource, action, ownerId)) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}
```

---

## 🎯 **Advanced Patterns**

### **Dynamic Permission Checking**

```typescript
// hooks/use-resource-permissions.ts
"use client";

import { usePermissions } from "./use-permissions";
import { RESOURCES } from "@/lib/permissions";

export function useResourcePermissions(resourceId?: string, ownerId?: string) {
  const { can } = usePermissions();

  return {
    canView: can.read(RESOURCES.RESOURCE, ownerId),
    canEdit: can.update(RESOURCES.RESOURCE, ownerId),
    canDelete: can.delete(RESOURCES.RESOURCE, ownerId),
    canCreate: can.create(RESOURCES.RESOURCE),
    canList: can.list(RESOURCES.RESOURCE),
  };
}
```

### **Permission-Based Navigation**

```typescript
// components/navigation.tsx
"use client";

import { usePermissions } from "@/hooks/use-permissions";
import { RESOURCES } from "@/lib/permissions";
import Link from "next/link";

export function Navigation() {
  const { can, is } = usePermissions();

  return (
    <nav>
      <Link href="/dashboard">Dashboard</Link>
      
      {can.list(RESOURCES.RESOURCE) && (
        <Link href="/resources">Resources</Link>
      )}
      
      {can.list(RESOURCES.CATEGORY) && (
        <Link href="/categories">Categories</Link>
      )}
      
      {is.admin() && (
        <Link href="/admin">Admin Panel</Link>
      )}
    </nav>
  );
}
```

---

## 🧪 **Testing Permissions**

### **Permission Test Helpers**

```typescript
// __tests__/helpers/permissions.ts
import { setupTestAuth } from "./auth";
import { UserRole } from "@/generated/prisma";

export async function setupAdminAuth() {
  const { user, session, headers } = await setupTestAuth();
  
  await prisma.user.update({
    where: { id: user.id },
    data: { role: UserRole.ADMIN },
  });

  return { user: { ...user, role: UserRole.ADMIN }, session, headers };
}

export async function testPermission(
  endpoint: string,
  method: "GET" | "POST" | "PUT" | "DELETE",
  headers: Record<string, string>,
  expectedStatus: number
) {
  const response = await fetch(endpoint, {
    method,
    headers,
  });
  
  expect(response.status).toBe(expectedStatus);
  return response;
}
```

### **Permission Test Examples**

```typescript
// __tests__/api/resources.permissions.test.ts
import { describe, it, expect } from "@jest/globals";
import { setupTestAuth, setupAdminAuth } from "../helpers/permissions";

describe("Resource Permissions", () => {
  it("should allow admin to access all resources", async () => {
    const { headers } = await setupAdminAuth();
    
    await testPermission("/api/resources", "GET", headers, 200);
    await testPermission("/api/resources", "POST", headers, 201);
  });

  it("should restrict user access to own resources", async () => {
    const { headers } = await setupTestAuth();
    
    await testPermission("/api/resources", "GET", headers, 200);
    await testPermission("/api/admin/users", "GET", headers, 403);
  });
});
```

---

## 📋 **Best Practices**

### **✅ Do:**

- Define clear resource and action constants
- Use the principle of least privilege
- Check permissions both client and server-side
- Filter data based on user permissions
- Test permission scenarios thoroughly
- Document permission requirements for each feature

### **❌ Don't:**

- Rely solely on client-side permission checks
- Hardcode role names throughout the application
- Skip permission checks in API routes
- Give excessive permissions by default
- Forget to handle permission errors gracefully

---

## 🔗 **Related Documentation**

- **[Better Auth Setup](./better-auth-setup.md)** - Core authentication configuration
- **[Admin Plugin](./admin-plugin-patterns.md)** - Admin plugin integration
- **[API Patterns](../core/06-API-PATTERNS.md)** - API route protection patterns

This permission system provides granular access control while maintaining simplicity and developer productivity for enterprise Next.js applications.
