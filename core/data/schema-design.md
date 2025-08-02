# Schema Design & Database Patterns

## 🗄️ Core Schema Principles

### Entity Base Pattern

All main entities must follow this structure:

```prisma
model EntityName {
  // Primary key
  id          String   @id @default(cuid())

  // Audit fields (required)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  createdById String
  updatedById String?
  status      Status   @default(ACTIVE)

  // Business fields
  name        String
  // ... other entity-specific fields

  // Audit relations
  createdBy   User     @relation("EntityCreatedBy", fields: [createdById], references: [id])
  updatedBy   User?    @relation("EntityUpdatedBy", fields: [updatedById], references: [id])

  // Business relations
  // ... entity-specific relations

  @@map("entity_name")  // snake_case table name
}
```

### Status Enum

```prisma
enum Status {
  ACTIVE
  INACTIVE
  DELETED
}
```

## 📊 Entity Examples

### User Entity (Core)

```prisma
model User {
  id          String   @id @default(cuid())
  name        String
  email       String   @unique
  image       String?
  emailVerified DateTime?

  // Audit fields
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  status      Status   @default(ACTIVE)

  // Sessions for Better Auth
  sessions    Session[]
  accounts    Account[]

  // Audit relations (created/updated by others)
  employeesCreated    Employee[]  @relation("EmployeeCreatedBy")
  employeesUpdated    Employee[]  @relation("EmployeeUpdatedBy")
  suppliersCreated    Supplier[]  @relation("SupplierCreatedBy")
  suppliersUpdated    Supplier[]  @relation("SupplierUpdatedBy")
  machineriesCreated  Machinery[] @relation("MachineryCreatedBy")
  machineriesUpdated  Machinery[] @relation("MachineryUpdatedBy")

  @@map("users")
}
```

### Employee Entity

```prisma
model Employee {
  id          String   @id @default(cuid())
  name        String
  email       String   @unique
  role        EmployeeRole
  mobilePhone String?

  // Audit fields
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  createdById String
  updatedById String?
  status      Status   @default(ACTIVE)

  // Audit relations
  createdBy   User     @relation("EmployeeCreatedBy", fields: [createdById], references: [id])
  updatedBy   User?    @relation("EmployeeUpdatedBy", fields: [updatedById], references: [id])

  @@map("employees")
}

enum EmployeeRole {
  MANAGER
  OPERATOR
  TECHNICIAN
  SUPERVISOR
}
```

### Supplier Entity with Categories (Many-to-Many)

```prisma
model Supplier {
  id           String   @id @default(cuid())
  name         String
  fantasyName  String?
  email        String?
  cnpj         String?  @unique

  // Address fields
  zipCode      String?
  address      String?
  number       String?
  complement   String?
  neighborhood String?
  city         String?
  state        String?
  country      String   @default("Brasil")

  // Contact fields
  homePhone    String?
  mobilePhone  String?
  agent        String?

  // Audit fields
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  createdById  String
  updatedById  String?
  status       Status   @default(ACTIVE)

  // Relations
  createdBy    User              @relation("SupplierCreatedBy", fields: [createdById], references: [id])
  updatedBy    User?             @relation("SupplierUpdatedBy", fields: [updatedById], references: [id])
  categories   SupplierCategory[] @relation("SupplierCategories")

  @@map("suppliers")
}

model SupplierCategory {
  id          String   @id @default(cuid())
  name        String   @unique
  description String?

  // Audit fields
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  createdById String
  updatedById String?
  status      Status   @default(ACTIVE)

  // Relations
  createdBy   User       @relation("SupplierCategoryCreatedBy", fields: [createdById], references: [id])
  updatedBy   User?      @relation("SupplierCategoryUpdatedBy", fields: [updatedById], references: [id])
  suppliers   Supplier[] @relation("SupplierCategories")

  @@map("supplier_categories")
}
```

### Machinery Entity (Property Domain)

```prisma
model Machinery {
  id          String      @id @default(cuid())
  name        String
  type        MachineryType
  model       String?
  brand       String?
  year        Int?
  hourlyRate  Decimal     @db.Decimal(10, 2)

  // Operational fields
  hoursWorked Decimal     @default(0) @db.Decimal(10, 2)
  lastMaintenance DateTime?
  nextMaintenance DateTime?

  // Audit fields
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  createdById String
  updatedById String?
  status      Status   @default(ACTIVE)

  // Relations
  createdBy   User     @relation("MachineryCreatedBy", fields: [createdById], references: [id])
  updatedBy   User?    @relation("MachineryUpdatedBy", fields: [updatedById], references: [id])

  @@map("machineries")
}

enum MachineryType {
  TRACTOR
  SPRAYER
  HARVESTER
  CHAINSAW
  VEHICLE
  OTHER
}
```

## 🔗 Relationship Patterns

### One-to-Many (User → Entities)

```prisma
// User model
model User {
  id               String     @id @default(cuid())
  employeesCreated Employee[] @relation("EmployeeCreatedBy")
  employeesUpdated Employee[] @relation("EmployeeUpdatedBy")
}

// Employee model
model Employee {
  id          String @id @default(cuid())
  createdById String
  updatedById String?

  createdBy   User   @relation("EmployeeCreatedBy", fields: [createdById], references: [id])
  updatedBy   User?  @relation("EmployeeUpdatedBy", fields: [updatedById], references: [id])
}
```

### Many-to-Many (Supplier ↔ Categories)

```prisma
// Prisma automatically creates junction table
model Supplier {
  id         String             @id @default(cuid())
  categories SupplierCategory[] @relation("SupplierCategories")
}

model SupplierCategory {
  id        String     @id @default(cuid())
  suppliers Supplier[] @relation("SupplierCategories")
}
```

### Self-Referencing (Categories with Hierarchy)

```prisma
model Category {
  id          String      @id @default(cuid())
  name        String
  parentId    String?

  parent      Category?   @relation("CategoryHierarchy", fields: [parentId], references: [id])
  children    Category[]  @relation("CategoryHierarchy")
}
```

## 🎯 Database Constraints

### Unique Constraints

```prisma
model User {
  email       String   @unique
  // ...
}

model Supplier {
  cnpj        String?  @unique
  // ...
}

model SupplierCategory {
  name        String   @unique
  // ...
}
```

### Composite Unique Constraints

```prisma
model UserRole {
  userId      String
  role        String

  user        User     @relation(fields: [userId], references: [id])

  @@unique([userId, role])
}
```

### Indexes for Performance

```prisma
model Employee {
  id          String   @id @default(cuid())
  email       String   @unique
  status      Status   @default(ACTIVE)
  createdAt   DateTime @default(now())

  // Index for common queries
  @@index([status])
  @@index([createdAt])
  @@index([status, createdAt])
}
```

## 📋 Field Type Patterns

### Common Field Types

```prisma
model Entity {
  // Primary keys
  id          String   @id @default(cuid())

  // Text fields
  name        String                    // Required text
  description String?                   // Optional text
  email       String   @unique          // Unique text

  // Numbers
  quantity    Int                       // Integer
  price       Decimal  @db.Decimal(10, 2) // Decimal with precision

  // Dates
  createdAt   DateTime @default(now())  // Auto timestamp
  updatedAt   DateTime @updatedAt       // Auto update timestamp
  eventDate   DateTime?                 // Optional date

  // Booleans
  isActive    Boolean  @default(true)   // Boolean with default

  // Enums
  status      Status   @default(ACTIVE) // Enum with default

  // JSON (use sparingly)
  metadata    Json?                     // Optional JSON field
}
```

### Money/Currency Pattern

```prisma
model Product {
  id          String   @id @default(cuid())
  name        String
  price       Decimal  @db.Decimal(10, 2)  // Always use Decimal for money
  currency    String   @default("BRL")      // Currency code
}
```

### Address Pattern

```prisma
model Entity {
  // Address fields grouped together
  zipCode      String?
  address      String?
  number       String?
  complement   String?
  neighborhood String?
  city         String?
  state        String?
  country      String   @default("Brasil")
}
```

## 🎯 Best Practices

### ✅ Do's

- Always include audit fields in main entities
- Use meaningful relation names with suffixes
- Follow snake_case for table names (@@map)
- Use enums for fixed value sets
- Index frequently queried fields
- Use Decimal for money values
- Group related fields together

### ❌ Don'ts

- Don't skip audit fields
- Don't use generic relation names
- Don't use Float for money
- Don't create unnecessary indexes
- Don't use JSON fields excessively
- Don't forget unique constraints where needed
- Don't use overly long field names
