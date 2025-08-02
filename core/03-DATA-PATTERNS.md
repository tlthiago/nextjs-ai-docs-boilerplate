# 🗄️ Database & Data Patterns

## **Overview**

This guide defines **database patterns and data management strategies** for Next.js enterprise applications using **PostgreSQL + Prisma**. All patterns prioritize **audit trails**, **data consistency**, and **AI agent compatibility**.

> 💡 **Philosophy**: Every data operation should be traceable, every entitF- **[🏗️ Schema Design](./data/schema-design.md)** - Schema design and conventions

- **[🔍 Query Patterns](./data/query-patterns.md)** - Optimized query patterns
- **[📚 Data Overview](./data/README.md)** - Complete data layer documentationAPI-related patterns:
- **[🚀 API Patterns](./api/README.md)** - API design patterns
- **[📋 Request/Response](./api/request-response.md)** - Request/response patterns
- **[🗂️ Route Structure](./api/route-structure.md)** - API route organization

> **Future Enhancements**: See [🔮 Data Improvements](./improvements/DATA-ENHANCEMENTS.md) for planned advanced features.ld follow consistent patterns, and every query should be predictable.

---

## 🗄️ **Database Architecture Overview**

### **Prisma ORM Stack**

- **PostgreSQL 17** - Primary database with ACID transactions
- **Prisma ORM** - Type-safe database client and migration tool
- **Audit Fields** - Automatic tracking in all entities
- **Soft Delete** - Status-based deletion pattern for data integrity

### **Schema Structure Pattern**

```
├── Core Entities
│   ├── User (Authentication & authorization)
│   └── Profile (User profile data)
├── Business Entities
│   ├── Resource (Main business entities)
│   ├── Category (Resource categorization)
│   └── ResourceCategory (Many-to-many junction)
└── System Entities
    ├── AuditLog (Change tracking)
    └── Settings (Application configuration)
```

---

## 🏗️ **Standard Entity Pattern**

### **Base Entity Template**

> 💡 For complete schema design patterns, advanced relationships, and database conventions, see **[🏗️ Schema Design](./data/schema-design.md)**.

```prisma
model Resource {
  // Primary key
  id          String   @id @default(cuid())

  // Business fields
  name        String
  description String?

  // Status management (soft delete)
  status      Status   @default(ACTIVE)

  // Audit fields (automatic tracking)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  createdById String
  updatedById String?

  // Relations (audit trail)
  createdBy   User     @relation("ResourceCreatedBy", fields: [createdById], references: [id])
  updatedBy   User?    @relation("ResourceUpdatedBy", fields: [updatedById], references: [id])

  // Many-to-many relations
  categories  ResourceCategory[]

  @@map("resources")
}

enum Status {
  ACTIVE
  INACTIVE
  DELETED
}
```

### **Audit Fields Implementation**

```typescript
// Every entity automatically includes:
{
  createdAt: DateTime,      // When record was created
  updatedAt: DateTime,      // Last modification timestamp
  createdById: string,      // User who created the record
  updatedById?: string,     // User who last updated the record
  status: Status            // ACTIVE | INACTIVE | DELETED
}
```

---

## 🔗 **Relationship Patterns**

### **Many-to-Many with Junction Table**

````prisma
## 🔗 **Relationship Patterns**

### **Many-to-Many (Implicit - Managed by Prisma)**

```prisma
// Resource can have many categories (implicit relation)
model Resource {
  id          String @id @default(cuid())
  name        String
  status      Status @default(ACTIVE)

  // Audit fields
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  createdById String
  updatedById String?

  // Many-to-Many relation (implicit)
  categories  Category[]

  // Audit relations
  createdBy   User     @relation("ResourceCreatedBy", fields: [createdById], references: [id])
  updatedBy   User?    @relation("ResourceUpdatedBy", fields: [updatedById], references: [id])

  @@map("resources")
}

// Category can belong to many resources
model Category {
  id          String @id @default(cuid())
  name        String
  status      Status @default(ACTIVE)

  // Audit fields
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  createdById String
  updatedById String?

  // Many-to-Many relation (implicit)
  resources   Resource[]

  // Audit relations
  createdBy   User     @relation("CategoryCreatedBy", fields: [createdById], references: [id])
  updatedBy   User?    @relation("CategoryUpdatedBy", fields: [updatedById], references: [id])

  @@map("categories")
}
````

> 💡 **Note**: Prisma automatically creates a junction table `_CategoryToResource` for implicit many-to-many relationships. For additional fields in the junction, use explicit relations as shown in **[🔗 Schema Design](./data/schema-design.md)**.

---

````

### **One-to-Many with Soft Delete**

```prisma
// User can have many profiles
model User {
  id           String    @id @default(cuid())
  email        String    @unique
  name         String
  status       Status    @default(ACTIVE)

  // Audit fields
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  deletedAt    DateTime?

  // One-to-Many relation
  profiles     Profile[]

  @@map("users")
}

model Profile {
  id           String    @id @default(cuid())
  name         String
  description  String?
  type         String    // e.g., "ADMIN", "MANAGER", "USER"
  status       Status    @default(ACTIVE)

  // Foreign key
  userId       String

  // Audit fields
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  deletedAt    DateTime?
  createdById  String?
  updatedById  String?

  // Relations
  user         User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  createdBy    User?     @relation("ProfileCreatedBy", fields: [createdById], references: [id])
  updatedBy    User?     @relation("ProfileUpdatedBy", fields: [updatedById], references: [id])

  @@map("profiles")
}
```

---

## 📊 **Query Patterns**

> 💡 For advanced query patterns, performance optimization, and complex filtering, see **[🔍 Query Patterns](./data/query-patterns.md)**.

### **Basic List Query**

```typescript
// Fetch resources with filtering and status exclusion
const resources = await prisma.resource.findMany({
  where: {
    status: { not: "DELETED" }, // Exclude soft-deleted
    name: { contains: searchTerm, mode: "insensitive" },
  },
  include: {
    categories: {
      where: { status: "ACTIVE" },
    },
  },
  orderBy: { createdAt: "desc" },
});
````

### **Query with Relationships**

```typescript
// Get resources with category filtering
const resources = await prisma.resource.findMany({
  where: {
    status: "ACTIVE",
    categories: {
      some: {
        name: categoryFilter,
      },
    },
  },
  include: {
    categories: true,
    createdBy: { select: { name: true } },
  },
});
```

### **Create with Audit Trail**

```typescript
const newResource = await prisma.resource.create({
  data: {
    ...resourceData,
    createdById: session.user.id, // Audit trail
    status: "ACTIVE",
  },
  include: {
    createdBy: { select: { name: true, email: true } },
  },
});
```

### **Update with Audit Trail**

```typescript
const updatedResource = await prisma.resource.update({
  where: { id },
  data: {
    ...updateData,
    updatedById: session.user.id, // Audit trail
    updatedAt: new Date(),
  },
  include: {
    updatedBy: { select: { name: true, email: true } },
  },
});
```

### **Soft Delete Pattern**

```typescript
// Never physically delete main entities
const deletedResource = await prisma.resource.update({
  where: { id },
  data: {
    status: "DELETED",
    deletedAt: new Date(),
    updatedById: session.user.id,
  },
});
```

---

## ✅ **Validation Schemas**

> 💡 For complete validation patterns, complex schemas, and validation strategies, see **[✅ Validation Schemas](./data/validation-schemas.md)**.

### **Zod Schema Template**

```typescript
// services/resources/schemas.ts
import { z } from "zod";

export const resourceSchema = z.object({
  name: z.string().min(1, "Name is required").max(255, "Name too long"),
  description: z.string().optional(),
  type: z.string().min(1, "Type is required"),
  status: z.enum(["ACTIVE", "INACTIVE"]).default("ACTIVE"),
});

export const resourceUpdateSchema = resourceSchema.partial();

export const resourceWithCategoriesSchema = resourceSchema.extend({
  categoryIds: z.array(z.string().cuid()).optional(),
});

export type ResourceInput = z.infer<typeof resourceSchema>;
export type ResourceUpdate = z.infer<typeof resourceUpdateSchema>;
export type ResourceWithCategories = z.infer<
  typeof resourceWithCategoriesSchema
>;
```

### **Complex Validation with Relationships**

```typescript
// services/users/schemas.ts
import { z } from "zod";

export const userSchema = z.object({
  email: z.string().email("Invalid email format"),
  name: z.string().min(2, "Name must be at least 2 characters"),
  status: z.enum(["ACTIVE", "INACTIVE"]).default("ACTIVE"),
});

export const profileSchema = z.object({
  name: z.string().min(1, "Profile name is required"),
  description: z.string().optional(),
  type: z.enum(["ADMIN", "MANAGER", "USER"]),
  userId: z.string().cuid("Invalid user ID"),
});

export const userWithProfilesSchema = userSchema.extend({
  profiles: z.array(profileSchema.omit({ userId: true })).optional(),
});

export type UserInput = z.infer<typeof userSchema>;
export type ProfileInput = z.infer<typeof profileSchema>;
export type UserWithProfiles = z.infer<typeof userWithProfilesSchema>;
```

---

## 📖 **Detailed Documentation**

For complete implementations and advanced patterns, consult:

- **[🏗️ Schema Design](./data/schema-design.md)** - Schema design and conventions
- **[🔍 Query Patterns](./data/query-patterns.md)** - Optimized query patterns
- **[� Data Overview](./data/README.md)** - Complete data layer documentation

For API-related patterns:

- **[🚀 API Patterns](./api/README.md)** - API design patterns
- **[📋 Request/Response](./api/request-response.md)** - Request/response patterns
- **[🗂️ Route Structure](./api/route-structure.md)** - API route organization

> **Future Enhancements**: See [� Data Improvements](./improvements/DATA-ENHANCEMENTS.md) for planned advanced features.

---

## 🎯 **Quick Guidelines**

### ✅ **Do's**

- Always include audit fields (`createdAt`, `updatedAt`, `createdById`, `updatedById`)
- Use soft delete pattern with status field
- Validate inputs with Zod schemas
- Include necessary relationships in queries
- Use transactions for multi-table operations
- Follow consistent naming conventions
- Add proper database indexes

### ❌ **Don'ts**

- Never physically delete main entities
- Don't skip input validation
- Avoid N+1 queries (use `include` or `select`)
- Don't expose sensitive data in API responses
- Avoid complex business logic in database queries
- Don't ignore database constraint violations

---

## 🚀 **AI Agent Prompt Template**

```
When working with this Next.js project's data layer:

1. **Database Schema**: Use Prisma with PostgreSQL, follow the base entity pattern with audit fields
2. **Status Management**: Implement soft delete with status enum (ACTIVE, INACTIVE, DELETED)
3. **Relationships**: Use proper foreign keys and junction tables for many-to-many
4. **Validation**: Create Zod schemas with English error messages
5. **Queries**: Include audit trails and exclude deleted records by default
6. **Naming**: Use camelCase for fields, snake_case for table names, descriptive relationship names

Reference the examples in this file for consistent implementation patterns.
```
