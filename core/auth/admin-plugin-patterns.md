# ⚡ Admin Plugin Patterns

## **Overview**

Better Auth admin plugin implementation for enterprise user management, role administration, and advanced access control patterns.

---

## 🔧 **Admin Plugin Configuration**

### **Plugin Setup with Access Control**

```typescript
// lib/auth.ts (Admin Plugin Section)
import {
  admin as adminPlugin,
  createAuthMiddleware,
} from "better-auth/plugins";
import { ac, roles } from "@/lib/permissions";
import { UserRole } from "@/generated/prisma";

export const auth = betterAuth({
  // ... other configuration
  plugins: [
    adminPlugin({
      ac, // Access control instance
      roles, // Role definitions
      defaultRole: UserRole.USER,
      adminRoles: UserRole.ADMIN,
    }),
  ],
});
```

### **Enhanced Permission Setup for Admin**

```typescript
// lib/permissions.ts (Extended for Admin)
import { AccessControl } from "accesscontrol";
import { UserRole } from "@/generated/prisma";

export const ADMIN_RESOURCES = {
  USER_MANAGEMENT: "user_management",
  SYSTEM_SETTINGS: "system_settings",
  AUDIT_LOGS: "audit_logs",
  ADMIN_PANEL: "admin_panel",
} as const;

// Extended access control with admin-specific permissions
export const ac = new AccessControl();

export const roles = {
  [UserRole.USER]: ac
    .grant(UserRole.USER)
    .readOwn("resource")
    .updateOwn("resource")
    .readOwn("profile")
    .updateOwn("profile"),

  [UserRole.ADMIN]: ac
    .grant(UserRole.ADMIN)
    .extend(UserRole.USER) // Inherit USER permissions
    // Resource management
    .createAny("resource")
    .readAny("resource")
    .updateAny("resource")
    .deleteAny("resource")
    // Category management
    .createAny("category")
    .readAny("category")
    .updateAny("category")
    .deleteAny("category")
    // User management
    .createAny("user")
    .readAny("user")
    .updateAny("user")
    .deleteAny("user")
    // Profile management
    .readAny("profile")
    .updateAny("profile")
    // Admin-specific resources
    .readAny(ADMIN_RESOURCES.USER_MANAGEMENT)
    .updateAny(ADMIN_RESOURCES.USER_MANAGEMENT)
    .readAny(ADMIN_RESOURCES.SYSTEM_SETTINGS)
    .updateAny(ADMIN_RESOURCES.SYSTEM_SETTINGS)
    .readAny(ADMIN_RESOURCES.AUDIT_LOGS)
    .readAny(ADMIN_RESOURCES.ADMIN_PANEL),
};

export type AdminResource = (typeof ADMIN_RESOURCES)[keyof typeof ADMIN_RESOURCES];
```

---

## 👥 **User Management Patterns**

### **Admin User Management Service**

```typescript
// lib/services/admin-user-service.ts
import { prisma } from "@/lib/prisma";
import { UserRole } from "@/generated/prisma";
import { requireRole } from "@/lib/auth-server";

export class AdminUserService {
  static async listUsers(filters?: {
    role?: UserRole;
    active?: boolean;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    await requireRole(UserRole.ADMIN);

    const {
      role,
      active,
      search,
      page = 1,
      limit = 20,
    } = filters || {};

    const where: any = {};

    if (role) where.role = role;
    if (typeof active === "boolean") where.active = active;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: "insensitive" } },
        { email: { contains: search, mode: "insensitive" } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          active: true,
          emailVerified: true,
          createdAt: true,
          updatedAt: true,
          _count: {
            select: {
              createdResources: true,
            },
          },
        },
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.user.count({ where }),
    ]);

    return {
      users,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  static async getUserById(userId: string) {
    await requireRole(UserRole.ADMIN);

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        createdResources: {
          select: {
            id: true,
            name: true,
            createdAt: true,
          },
          orderBy: { createdAt: "desc" },
          take: 5,
        },
        _count: {
          select: {
            createdResources: true,
            sessions: true,
          },
        },
      },
    });

    if (!user) {
      throw new Error("User not found");
    }

    return user;
  }

  static async updateUser(
    userId: string,
    updates: {
      name?: string;
      role?: UserRole;
      active?: boolean;
    }
  ) {
    await requireRole(UserRole.ADMIN);

    const user = await prisma.user.update({
      where: { id: userId },
      data: updates,
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        active: true,
        emailVerified: true,
        updatedAt: true,
      },
    });

    return user;
  }

  static async deactivateUser(userId: string) {
    await requireRole(UserRole.ADMIN);

    // Deactivate user
    const user = await prisma.user.update({
      where: { id: userId },
      data: { active: false },
    });

    // Invalidate all user sessions
    await prisma.session.deleteMany({
      where: { userId },
    });

    return user;
  }

  static async createUser(userData: {
    email: string;
    name: string;
    role: UserRole;
    password: string;
  }) {
    await requireRole(UserRole.ADMIN);

    // Use Better Auth to create user with admin privileges
    const result = await auth.api.signUp.email({
      body: userData,
    });

    if (!result.success) {
      throw new Error("Failed to create user");
    }

    return result.data;
  }
}
```

---

## 🔗 **Admin API Routes**

### **User Management API**

```typescript
// app/api/admin/users/route.ts
import { withRole } from "@/lib/api-auth";
import { AdminUserService } from "@/lib/services/admin-user-service";
import { UserRole } from "@/generated/prisma";
import { z } from "zod";

const userListSchema = z.object({
  role: z.nativeEnum(UserRole).optional(),
  active: z.coerce.boolean().optional(),
  search: z.string().optional(),
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(20),
});

export const GET = withRole(UserRole.ADMIN, async (req, session) => {
  try {
    const { searchParams } = new URL(req.url);
    const filters = userListSchema.parse(Object.fromEntries(searchParams));

    const result = await AdminUserService.listUsers(filters);
    return Response.json(result);
  } catch (error) {
    console.error("Admin users list error:", error);
    return Response.json(
      { error: "Failed to fetch users" },
      { status: 500 }
    );
  }
});

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  role: z.nativeEnum(UserRole),
  password: z.string().min(8),
});

export const POST = withRole(UserRole.ADMIN, async (req, session) => {
  try {
    const body = await req.json();
    const userData = createUserSchema.parse(body);

    const user = await AdminUserService.createUser(userData);
    return Response.json(user, { status: 201 });
  } catch (error) {
    console.error("Admin create user error:", error);
    
    if (error instanceof z.ZodError) {
      return Response.json(
        { error: "Invalid user data", details: error.errors },
        { status: 400 }
      );
    }

    return Response.json(
      { error: "Failed to create user" },
      { status: 500 }
    );
  }
});
```

### **Individual User Management**

```typescript
// app/api/admin/users/[id]/route.ts
import { withRole } from "@/lib/api-auth";
import { AdminUserService } from "@/lib/services/admin-user-service";
import { UserRole } from "@/generated/prisma";
import { z } from "zod";

const updateUserSchema = z.object({
  name: z.string().min(1).optional(),
  role: z.nativeEnum(UserRole).optional(),
  active: z.boolean().optional(),
});

export const GET = withRole(UserRole.ADMIN, async (req, session, { params }) => {
  try {
    const user = await AdminUserService.getUserById(params.id);
    return Response.json(user);
  } catch (error) {
    console.error("Admin get user error:", error);
    return Response.json(
      { error: "User not found" },
      { status: 404 }
    );
  }
});

export const PATCH = withRole(UserRole.ADMIN, async (req, session, { params }) => {
  try {
    const body = await req.json();
    const updates = updateUserSchema.parse(body);

    const user = await AdminUserService.updateUser(params.id, updates);
    return Response.json(user);
  } catch (error) {
    console.error("Admin update user error:", error);
    
    if (error instanceof z.ZodError) {
      return Response.json(
        { error: "Invalid update data", details: error.errors },
        { status: 400 }
      );
    }

    return Response.json(
      { error: "Failed to update user" },
      { status: 500 }
    );
  }
});

export const DELETE = withRole(UserRole.ADMIN, async (req, session, { params }) => {
  try {
    await AdminUserService.deactivateUser(params.id);
    return Response.json({ message: "User deactivated successfully" });
  } catch (error) {
    console.error("Admin deactivate user error:", error);
    return Response.json(
      { error: "Failed to deactivate user" },
      { status: 500 }
    );
  }
});
```

---

## 🎯 **Admin Dashboard Components**

### **User Management Table**

```typescript
// components/admin/user-management-table.tsx
"use client";

import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, UserCheck, UserX, Edit } from "lucide-react";
import { UserRole } from "@/generated/prisma";

interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  active: boolean;
  emailVerified: boolean;
  createdAt: string;
  _count: {
    createdResources: number;
  };
}

export function UserManagementTable() {
  const [page, setPage] = useState(1);
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ["admin-users", page],
    queryFn: async () => {
      const response = await fetch(`/api/admin/users?page=${page}`);
      if (!response.ok) throw new Error("Failed to fetch users");
      return response.json();
    },
  });

  const updateUserMutation = useMutation({
    mutationFn: async ({
      userId,
      updates,
    }: {
      userId: string;
      updates: Partial<User>;
    }) => {
      const response = await fetch(`/api/admin/users/${userId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(updates),
      });
      if (!response.ok) throw new Error("Failed to update user");
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-users"] });
    },
  });

  const deactivateUserMutation = useMutation({
    mutationFn: async (userId: string) => {
      const response = await fetch(`/api/admin/users/${userId}`, {
        method: "DELETE",
      });
      if (!response.ok) throw new Error("Failed to deactivate user");
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-users"] });
    },
  });

  const handleToggleActive = (user: User) => {
    updateUserMutation.mutate({
      userId: user.id,
      updates: { active: !user.active },
    });
  };

  const handleRoleChange = (user: User, newRole: UserRole) => {
    updateUserMutation.mutate({
      userId: user.id,
      updates: { role: newRole },
    });
  };

  if (isLoading) {
    return <div>Loading users...</div>;
  }

  const { users, pagination } = data || { users: [], pagination: {} };

  return (
    <div className="space-y-4">
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>User</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Resources</TableHead>
              <TableHead>Created</TableHead>
              <TableHead className="w-[70px]">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {users.map((user: User) => (
              <TableRow key={user.id}>
                <TableCell>
                  <div>
                    <div className="font-medium">{user.name}</div>
                    <div className="text-sm text-gray-500">{user.email}</div>
                  </div>
                </TableCell>
                <TableCell>
                  <Badge variant={user.role === UserRole.ADMIN ? "default" : "secondary"}>
                    {user.role}
                  </Badge>
                </TableCell>
                <TableCell>
                  <div className="flex flex-col gap-1">
                    <Badge variant={user.active ? "default" : "destructive"}>
                      {user.active ? "Active" : "Inactive"}
                    </Badge>
                    {!user.emailVerified && (
                      <Badge variant="outline" className="text-xs">
                        Unverified
                      </Badge>
                    )}
                  </div>
                </TableCell>
                <TableCell>{user._count.createdResources}</TableCell>
                <TableCell>
                  {new Date(user.createdAt).toLocaleDateString()}
                </TableCell>
                <TableCell>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" className="h-8 w-8 p-0">
                        <MoreHorizontal className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onClick={() => handleToggleActive(user)}>
                        {user.active ? (
                          <>
                            <UserX className="mr-2 h-4 w-4" />
                            Deactivate
                          </>
                        ) : (
                          <>
                            <UserCheck className="mr-2 h-4 w-4" />
                            Activate
                          </>
                        )}
                      </DropdownMenuItem>
                      <DropdownMenuItem
                        onClick={() =>
                          handleRoleChange(
                            user,
                            user.role === UserRole.ADMIN ? UserRole.USER : UserRole.ADMIN
                          )
                        }
                      >
                        <Edit className="mr-2 h-4 w-4" />
                        {user.role === UserRole.ADMIN ? "Make User" : "Make Admin"}
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <div className="text-sm text-gray-500">
          Showing {users.length} of {pagination.total} users
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            disabled={page === 1}
            onClick={() => setPage(page - 1)}
          >
            Previous
          </Button>
          <Button
            variant="outline"
            size="sm"
            disabled={page >= pagination.pages}
            onClick={() => setPage(page + 1)}
          >
            Next
          </Button>
        </div>
      </div>
    </div>
  );
}
```

### **Create User Dialog**

```typescript
// components/admin/create-user-dialog.tsx
"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { UserPlus } from "lucide-react";
import { UserRole } from "@/generated/prisma";

const createUserSchema = z.object({
  email: z.string().email("Invalid email address"),
  name: z.string().min(1, "Name is required"),
  role: z.nativeEnum(UserRole),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

type CreateUserFormData = z.infer<typeof createUserSchema>;

export function CreateUserDialog() {
  const [open, setOpen] = useState(false);
  const queryClient = useQueryClient();

  const form = useForm<CreateUserFormData>({
    resolver: zodResolver(createUserSchema),
    defaultValues: {
      email: "",
      name: "",
      role: UserRole.USER,
      password: "",
    },
  });

  const createUserMutation = useMutation({
    mutationFn: async (data: CreateUserFormData) => {
      const response = await fetch("/api/admin/users", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      if (!response.ok) throw new Error("Failed to create user");
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-users"] });
      setOpen(false);
      form.reset();
    },
  });

  const onSubmit = (data: CreateUserFormData) => {
    createUserMutation.mutate(data);
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
          <UserPlus className="mr-2 h-4 w-4" />
          Create User
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Create New User</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Full Name</FormLabel>
                  <FormControl>
                    <Input {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

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
              name="role"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Role</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      <SelectItem value={UserRole.USER}>User</SelectItem>
                      <SelectItem value={UserRole.ADMIN}>Admin</SelectItem>
                    </SelectContent>
                  </Select>
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

            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={createUserMutation.isPending}>
                {createUserMutation.isPending ? "Creating..." : "Create User"}
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
```

---

## 🎛️ **Admin Dashboard Layout**

### **Protected Admin Layout**

```typescript
// app/admin/layout.tsx
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth-server";
import { UserRole } from "@/generated/prisma";
import { AdminSidebar } from "@/components/admin/admin-sidebar";

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getSession();

  if (!session) {
    redirect("/login");
  }

  if (session.user.role !== UserRole.ADMIN) {
    redirect("/dashboard");
  }

  return (
    <div className="flex h-screen">
      <AdminSidebar />
      <main className="flex-1 overflow-y-auto p-6">
        {children}
      </main>
    </div>
  );
}
```

### **Admin Sidebar Navigation**

```typescript
// components/admin/admin-sidebar.tsx
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { 
  Users, 
  Settings, 
  BarChart3, 
  Shield,
  FileText 
} from "lucide-react";

const navigation = [
  {
    name: "Dashboard",
    href: "/admin",
    icon: BarChart3,
  },
  {
    name: "User Management",
    href: "/admin/users",
    icon: Users,
  },
  {
    name: "Permissions",
    href: "/admin/permissions",
    icon: Shield,
  },
  {
    name: "Settings",
    href: "/admin/settings",
    icon: Settings,
  },
  {
    name: "Audit Logs",
    href: "/admin/audit",
    icon: FileText,
  },
];

export function AdminSidebar() {
  const pathname = usePathname();

  return (
    <div className="w-64 bg-gray-900 text-white">
      <div className="p-6">
        <h2 className="text-lg font-semibold">Admin Panel</h2>
      </div>
      <nav className="mt-6">
        {navigation.map((item) => {
          const Icon = item.icon;
          const isActive = pathname === item.href;
          
          return (
            <Link key={item.name} href={item.href}>
              <Button
                variant="ghost"
                className={cn(
                  "w-full justify-start text-white hover:bg-gray-800",
                  isActive && "bg-gray-800"
                )}
              >
                <Icon className="mr-3 h-4 w-4" />
                {item.name}
              </Button>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
```

---

## 🧪 **Testing Admin Features**

### **Admin API Tests**

```typescript
// __tests__/admin/user-management.test.ts
import { describe, it, expect } from "@jest/globals";
import { setupAdminAuth, setupTestAuth } from "../helpers/permissions";

describe("Admin User Management", () => {
  it("should allow admin to list users", async () => {
    const { headers } = await setupAdminAuth();
    
    const response = await fetch("/api/admin/users", { headers });
    expect(response.status).toBe(200);
    
    const data = await response.json();
    expect(data).toHaveProperty("users");
    expect(data).toHaveProperty("pagination");
  });

  it("should deny regular user access to admin endpoints", async () => {
    const { headers } = await setupTestAuth();
    
    const response = await fetch("/api/admin/users", { headers });
    expect(response.status).toBe(403);
  });

  it("should allow admin to create users", async () => {
    const { headers } = await setupAdminAuth();
    
    const userData = {
      email: "newuser@company.com",
      name: "New User",
      role: "USER",
      password: "StrongPassword123",
    };

    const response = await fetch("/api/admin/users", {
      method: "POST",
      headers: { ...headers, "Content-Type": "application/json" },
      body: JSON.stringify(userData),
    });

    expect(response.status).toBe(201);
  });
});
```

---

## 📋 **Best Practices**

### **✅ Do:**

- Always validate admin permissions on both client and server
- Use the admin plugin's built-in access control features
- Implement comprehensive audit logging for admin actions
- Provide clear feedback for admin operations
- Use role-based access control consistently
- Test admin functionality thoroughly

### **❌ Don't:**

- Skip permission checks in admin routes
- Allow admin operations without proper validation
- Expose sensitive user data unnecessarily
- Forget to handle admin operation errors gracefully
- Hard-code admin permissions in components
- Allow self-modification of admin status

---

## 🔗 **Related Documentation**

- **[Better Auth Setup](./better-auth-setup.md)** - Core authentication configuration
- **[Permission System](./permission-system.md)** - Role-based access control
- **[Email Verification](./email-verification.md)** - User verification management

This admin plugin implementation provides enterprise-grade user management with comprehensive access control and intuitive administration interface.
