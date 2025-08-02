# Route Structure & Conventions

## 🛣️ API Route Architecture

### Base URL Structure

```
/api/v1/{domain}/{resource}/
```

### Domain Organization

```
/api/v1/
├── auth/                    # Authentication domain
│   ├── sign-in/email/
│   ├── sign-up/email/
│   └── verify-email/
├── employees/               # Employee management
├── resources/               # Resource management
│   ├── categories/          # Supplier categories
│   └── [id]/               # Individual supplier operations
└── properties/              # Property resources
    ├── machineries/         # Machines and equipment
    ├── implements/          # Agricultural implements
    └── control-units/       # Control units
```

## 📋 Standard CRUD Routes

### Resource Collection Routes

```typescript
// /api/v1/employees/route.ts
GET    /api/v1/employees/           # List all employees (with filters)
POST   /api/v1/employees/           # Create new employee
```

### Individual Resource Routes

```typescript
// /api/v1/employees/[id]/route.ts
GET    /api/v1/employees/{id}       # Get employee by ID
PATCH  /api/v1/employees/{id}       # Update employee
DELETE /api/v1/employees/{id}       # Soft delete employee
```

### Status Toggle Routes

```typescript
// /api/v1/employees/[id]/status/route.ts
PATCH  /api/v1/employees/{id}/status # Toggle employee status (ACTIVE/INACTIVE)
```

## 🗂️ File Organization

### Directory Structure

```
app/api/v1/
├── employees/
│   ├── route.ts                    # Collection operations (GET, POST)
│   └── [id]/
│       ├── route.ts                # Individual operations (GET, PATCH, DELETE)
│       └── status/
│           └── route.ts            # Status toggle (PATCH)
├── suppliers/
│   ├── route.ts
│   ├── [id]/
│   │   ├── route.ts
│   │   └── status/
│   │       └── route.ts
│   └── categories/
│       ├── route.ts
│       └── [id]/
│           └── route.ts
└── properties/
    └── machineries/
        ├── route.ts
        └── [id]/
            ├── route.ts
            └── status/
                └── route.ts
```

## 🎯 Route Implementation Patterns

### Collection Route Template

```typescript
// /api/v1/{resource}/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getAuthenticatedSession } from "@/lib/api/api-guard";
import { handleError } from "@/lib/errors/error-handler";
import prisma from "@/lib/prisma";
import { resourceSchema } from "@/services/{resource}/schemas";

export async function GET() {
  await getAuthenticatedSession();

  try {
    const resources = await prisma.{resource}.findMany({
      where: { status: { not: "DELETED" } },
      orderBy: { createdAt: "desc" },
    });

    return NextResponse.json({ data: resources });
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(request: NextRequest) {
  const session = await getAuthenticatedSession();

  try {
    const body = await request.json();
    const data = resourceSchema.parse(body);

    const resource = await prisma.{resource}.create({
      data: {
        ...data,
        createdById: session.user.id,
      },
    });

    return NextResponse.json(
      { data: resource, message: "Recurso criado com sucesso" },
      { status: 201 }
    );
  } catch (error) {
    return handleError(error);
  }
}
```

### Individual Resource Route Template

```typescript
// /api/v1/{resource}/[id]/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getAuthenticatedSession } from "@/lib/api/api-guard";
import { NotFoundError } from "@/lib/errors/api-errors";
import { handleError } from "@/lib/errors/error-handler";
import prisma from "@/lib/prisma";
import { resourceSchema } from "@/services/{resource}/schemas";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  await getAuthenticatedSession();
  const { id } = await params;

  try {
    const resource = await prisma.{resource}.findUnique({
      where: { id },
      include: {
        // Include necessary relations
      },
    });

    if (!resource) {
      throw new NotFoundError("Recurso não encontrado");
    }

    return NextResponse.json({ data: resource });
  } catch (error) {
    return handleError(error);
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getAuthenticatedSession();
  const { id } = await params;

  try {
    const existingResource = await prisma.{resource}.findUnique({
      where: { id },
    });

    if (!existingResource) {
      throw new NotFoundError("Recurso não encontrado");
    }

    const body = await request.json();
    const data = resourceSchema.parse(body);

    const updatedResource = await prisma.{resource}.update({
      where: { id },
      data: {
        ...data,
        updatedById: session.user.id,
      },
    });

    return NextResponse.json({
      data: updatedResource,
      message: "Recurso atualizado com sucesso",
    });
  } catch (error) {
    return handleError(error);
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getAuthenticatedSession();
  const { id } = await params;

  try {
    const existingResource = await prisma.{resource}.findUnique({
      where: { id },
    });

    if (!existingResource) {
      throw new NotFoundError("Recurso não encontrado");
    }

    // Soft delete - never physically delete main entities
    const deletedResource = await prisma.{resource}.update({
      where: { id },
      data: {
        status: "DELETED",
        updatedById: session.user.id,
      },
    });

    return NextResponse.json({
      data: deletedResource,
      message: "Recurso excluído com sucesso",
    });
  } catch (error) {
    return handleError(error);
  }
}
```

### Status Toggle Route Template

```typescript
// /api/v1/{resource}/[id]/status/route.ts
import { NextRequest, NextResponse } from "next/server";
import { Status } from "@prisma/client";
import { getAuthenticatedSession } from "@/lib/api/api-guard";
import { NotFoundError } from "@/lib/errors/api-errors";
import { handleError } from "@/lib/errors/error-handler";
import prisma from "@/lib/prisma";

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await getAuthenticatedSession();
  const { id } = await params;

  try {
    const existingResource = await prisma.{resource}.findUnique({
      where: { id },
    });

    if (!existingResource) {
      throw new NotFoundError("Recurso não encontrado");
    }

    const newStatus = existingResource.status === "ACTIVE"
      ? Status.INACTIVE
      : Status.ACTIVE;

    const updatedResource = await prisma.{resource}.update({
      where: { id },
      data: {
        status: newStatus,
        updatedById: session.user.id,
      },
    });

    return NextResponse.json({
      data: updatedResource,
      message: `Status ${newStatus.toLowerCase()} aplicado com sucesso`,
    });
  } catch (error) {
    return handleError(error);
  }
}
```

## 🔧 Query Parameters

### List Endpoints Query Support

```typescript
// GET /api/v1/employees?status=ACTIVE&search=João&page=1&limit=10
export async function GET(request: NextRequest) {
  await getAuthenticatedSession();

  const { searchParams } = new URL(request.url);
  const status = searchParams.get("status");
  const search = searchParams.get("search");
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "10");

  try {
    const where = {
      AND: [
        { status: { not: "DELETED" } },
        status ? { status } : {},
        search
          ? {
              OR: [
                { name: { contains: search, mode: "insensitive" } },
                { email: { contains: search, mode: "insensitive" } },
              ],
            }
          : {},
      ],
    };

    const [resources, total] = await Promise.all([
      prisma.resource.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: "desc" },
      }),
      prisma.resource.count({ where }),
    ]);

    return NextResponse.json({
      data: resources,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return handleError(error);
  }
}
```

## 🎯 Best Practices

### ✅ Do's

- Sempre usar autenticação em todas as rotas
- Implementar soft delete para entidades principais
- Validar dados com Zod schemas
- Usar audit fields (createdBy, updatedBy)
- Retornar responses padronizadas
- Implementar filtros e paginação

### ❌ Don'ts

- Nunca deletar fisicamente registros principais
- Não ignorar validação de dados
- Não retornar senhas ou dados sensíveis
- Não criar rotas sem autenticação
- Não usar diferentes formatos de response
- Não esquecer de incluir relacionamentos necessários
