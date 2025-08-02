# Query Patterns & Performance

## 🔍 Basic Query Patterns

### Find Operations

#### List All Resources

```typescript
// Get all active resources
const employees = await prisma.employee.findMany({
  where: {
    status: { not: "DELETED" },
  },
  orderBy: {
    createdAt: "desc",
  },
});
```

#### Find with Filters

```typescript
// Multiple filters
const employees = await prisma.employee.findMany({
  where: {
    AND: [
      { status: { not: "DELETED" } },
      { role: "MANAGER" },
      {
        OR: [
          { name: { contains: searchTerm, mode: "insensitive" } },
          { email: { contains: searchTerm, mode: "insensitive" } },
        ],
      },
    ],
  },
  orderBy: [{ status: "asc" }, { name: "asc" }],
});
```

#### Find Unique Resource

```typescript
// Find by ID with relations
const supplier = await prisma.supplier.findUnique({
  where: { id },
  include: {
    categories: {
      where: { status: { not: "DELETED" } },
      select: {
        id: true,
        name: true,
      },
    },
    createdBy: {
      select: {
        id: true,
        name: true,
      },
    },
  },
});

// Handle not found
if (!supplier) {
  throw new NotFoundError("Fornecedor não encontrado");
}
```

### Pagination Pattern

```typescript
// Paginated list with count
export async function getPaginatedEmployees(
  page: number = 1,
  limit: number = 10,
  filters: EmployeeFilters = {},
) {
  const skip = (page - 1) * limit;

  const where = {
    AND: [
      { status: { not: "DELETED" } },
      filters.status ? { status: filters.status } : {},
      filters.role ? { role: filters.role } : {},
      filters.search
        ? {
            OR: [
              { name: { contains: filters.search, mode: "insensitive" } },
              { email: { contains: filters.search, mode: "insensitive" } },
            ],
          }
        : {},
    ],
  };

  const [employees, total] = await Promise.all([
    prisma.employee.findMany({
      where,
      skip,
      take: limit,
      orderBy: { createdAt: "desc" },
      include: {
        createdBy: {
          select: { id: true, name: true },
        },
      },
    }),
    prisma.employee.count({ where }),
  ]);

  return {
    data: employees,
    meta: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}
```

## 🔗 Relationship Queries

### Include vs Select

```typescript
// Include - gets all fields + relations
const supplier = await prisma.supplier.findUnique({
  where: { id },
  include: {
    categories: true, // All category fields
    createdBy: true, // All user fields
  },
});

// Select - choose specific fields
const supplier = await prisma.supplier.findUnique({
  where: { id },
  select: {
    id: true,
    name: true,
    email: true,
    categories: {
      select: {
        id: true,
        name: true,
      },
    },
    createdBy: {
      select: {
        id: true,
        name: true,
      },
    },
  },
});
```

### Nested Filtering

```typescript
// Find suppliers with active categories only
const suppliers = await prisma.supplier.findMany({
  where: {
    status: { not: "DELETED" },
    categories: {
      some: {
        status: "ACTIVE",
      },
    },
  },
  include: {
    categories: {
      where: { status: "ACTIVE" },
      select: { id: true, name: true },
    },
  },
});
```

### Counting Relations

```typescript
// Count related records
const suppliersWithCategoryCount = await prisma.supplier.findMany({
  where: { status: { not: "DELETED" } },
  include: {
    _count: {
      select: {
        categories: {
          where: { status: "ACTIVE" },
        },
      },
    },
  },
});
```

## 🎯 CRUD Operations

### Create with Relations

```typescript
// Create supplier with categories
const newSupplier = await prisma.supplier.create({
  data: {
    name: "Fornecedor Exemplo",
    email: "contato@fornecedor.com",
    createdById: userId,
    categories: {
      connect: categoryIds.map((id) => ({ id })),
    },
  },
  include: {
    categories: {
      select: { id: true, name: true },
    },
  },
});

// Create with nested relations
const employeeWithDetails = await prisma.employee.create({
  data: {
    name: "João Silva",
    email: "joao@empresa.com",
    role: "MANAGER",
    createdById: userId,
    // Nested create if needed
    profile: {
      create: {
        bio: "Gerente experiente",
        phone: "11999999999",
      },
    },
  },
});
```

### Update with Relations

```typescript
// Update supplier and categories
const updatedSupplier = await prisma.supplier.update({
  where: { id },
  data: {
    name: data.name,
    email: data.email,
    updatedById: userId,
    categories: {
      set: [], // Clear all existing
      connect: data.categoryIds.map((id) => ({ id })), // Add new ones
    },
  },
  include: {
    categories: {
      select: { id: true, name: true },
    },
  },
});

// Partial update with conditional fields
const updateData: Prisma.EmployeeUpdateInput = {
  updatedById: userId,
  ...(data.name && { name: data.name }),
  ...(data.email && { email: data.email }),
  ...(data.role && { role: data.role }),
};

const updatedEmployee = await prisma.employee.update({
  where: { id },
  data: updateData,
});
```

### Soft Delete Pattern

```typescript
// Soft delete (preferred for main entities)
const deletedSupplier = await prisma.supplier.update({
  where: { id },
  data: {
    status: "DELETED",
    updatedById: userId,
  },
});

// Cascade soft delete related records if needed
await prisma.supplierContact.updateMany({
  where: { supplierId: id },
  data: {
    status: "DELETED",
    updatedById: userId,
  },
});
```

## 📊 Advanced Query Patterns

### Aggregations

```typescript
// Count, sum, average
const machineryStats = await prisma.machinery.aggregate({
  where: { status: "ACTIVE" },
  _count: { id: true },
  _sum: { hourlyRate: true },
  _avg: { hourlyRate: true },
  _max: { hourlyRate: true },
  _min: { hourlyRate: true },
});

// Group by with aggregation
const employeesByRole = await prisma.employee.groupBy({
  by: ["role"],
  where: { status: { not: "DELETED" } },
  _count: { id: true },
  orderBy: { _count: { id: "desc" } },
});
```

### Complex Filtering

```typescript
// Date range queries
const recentEmployees = await prisma.employee.findMany({
  where: {
    createdAt: {
      gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
      lte: new Date(),
    },
  },
});

// Multiple relation filters
const suppliersWithActiveCategories = await prisma.supplier.findMany({
  where: {
    AND: [
      { status: "ACTIVE" },
      {
        categories: {
          some: {
            AND: [
              { status: "ACTIVE" },
              { name: { contains: "categoria", mode: "insensitive" } },
            ],
          },
        },
      },
    ],
  },
});
```

### Raw Queries (when needed)

```typescript
// Use raw queries sparingly for complex operations
const result = await prisma.$queryRaw`
  SELECT 
    s.name,
    COUNT(sc.id) as category_count
  FROM suppliers s
  LEFT JOIN _SupplierCategories sc ON s.id = sc.A
  WHERE s.status != 'DELETED'
  GROUP BY s.id, s.name
  HAVING COUNT(sc.id) > 2
  ORDER BY category_count DESC
`;
```

## ⚡ Performance Optimization

### Query Optimization

```typescript
// ✅ Good: Select only needed fields
const employees = await prisma.employee.findMany({
  select: {
    id: true,
    name: true,
    email: true,
    role: true,
    status: true,
  },
});

// ❌ Bad: Getting all fields when not needed
const employees = await prisma.employee.findMany();
```

### Batch Operations

```typescript
// Batch create
const newEmployees = await prisma.employee.createMany({
  data: [
    { name: "João", email: "joao@empresa.com", createdById: userId },
    { name: "Maria", email: "maria@empresa.com", createdById: userId },
  ],
  skipDuplicates: true,
});

// Batch update
await prisma.employee.updateMany({
  where: { role: "OPERATOR" },
  data: { updatedById: userId },
});
```

### Connection Pooling

```typescript
// Configure in lib/prisma.ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: ["query", "error", "warn"],
    datasources: {
      db: {
        url: process.env.DATABASE_URL,
      },
    },
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
```

## 🎯 Best Practices

### ✅ Do's

- Always filter out DELETED records
- Use select to get only needed fields
- Include relations efficiently
- Implement pagination for large datasets
- Use transactions for related operations
- Handle not found cases explicitly
- Use indexes for frequently queried fields

### ❌ Don'ts

- Don't use findMany without limits for large tables
- Don't fetch unnecessary relations
- Don't use N+1 queries (use include/select)
- Don't ignore database constraints
- Don't use raw queries unless necessary
- Don't forget to handle connection limits
- Don't hardcode filter values
