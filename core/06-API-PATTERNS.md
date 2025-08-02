# API Patterns - Avocado HP

> **📚 Documentação Fragmentada**: Esta é uma versão resumida. Para detalhes completos, consulte a [documentação modular em `/docs/api/`](./api/).

## 🛣️ API Architecture Overview

### Route Structure

```
/api/v1/{domain}/{resource}/
├── GET    /           # List all (with pagination and filters)
├── POST   /           # Create new
├── GET    /:id        # Get by ID
├── PATCH  /:id        # Update
├── PATCH  /:id/status # Toggle status
└── DELETE /:id        # Soft delete
```

### Standard Response Format

```typescript
// Success
{ data: T, message?: string }

// Error
{ error: { message: string, code: string, statusCode: number } }
```

## 📋 Quick Implementation Reference

### Basic Route Template

```typescript
// /api/v1/employees/route.ts
import { getAuthenticatedSession } from "@/lib/api/api-guard";
import { handleError } from "@/lib/errors/error-handler";
import prisma from "@/lib/prisma";
import { employeeSchema } from "@/services/employees/schemas";

export async function GET() {
  await getAuthenticatedSession();

  try {
    const employees = await prisma.employee.findMany({
      where: { status: { not: "DELETED" } },
      orderBy: { createdAt: "desc" },
    });

    return NextResponse.json({ data: employees });
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(request: NextRequest) {
  const session = await getAuthenticatedSession();

  try {
    const body = await request.json();
    const data = employeeSchema.parse(body);

    const employee = await prisma.employee.create({
      data: { ...data, createdById: session.user.id },
    });

    return NextResponse.json(
      { data: employee, message: "Funcionário criado com sucesso" },
      { status: 201 },
    );
  } catch (error) {
    return handleError(error);
  }
}
```

### Individual Resource Template

```typescript
// /api/v1/employees/[id]/route.ts
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  await getAuthenticatedSession();
  const { id } = await params;

  try {
    const employee = await prisma.employee.findUnique({
      where: { id },
    });

    if (!employee) {
      throw new NotFoundError("Funcionário não encontrado");
    }

    return NextResponse.json({ data: employee });
  } catch (error) {
    return handleError(error);
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const session = await getAuthenticatedSession();
  const { id } = await params;

  try {
    const body = await request.json();
    const data = employeeSchema.parse(body);

    const updatedEmployee = await prisma.employee.update({
      where: { id },
      data: { ...data, updatedById: session.user.id },
    });

    return NextResponse.json({
      data: updatedEmployee,
      message: "Funcionário atualizado com sucesso",
    });
  } catch (error) {
    return handleError(error);
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const session = await getAuthenticatedSession();
  const { id } = await params;

  try {
    // Soft delete - never physically delete main entities
    const deletedEmployee = await prisma.employee.update({
      where: { id },
      data: { status: "DELETED", updatedById: session.user.id },
    });

    return NextResponse.json({
      data: deletedEmployee,
      message: "Funcionário excluído com sucesso",
    });
  } catch (error) {
    return handleError(error);
  }
}
```

## 📊 Status Codes & Error Handling

### Standard Status Codes

- `200` - OK (GET, PATCH, DELETE)
- `201` - Created (POST)
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `422` - Validation Error
- `500` - Server Error

### Error Response Example

```typescript
{
  "error": {
    "message": "Dados inválidos",
    "code": "VALIDATION_ERROR",
    "statusCode": 422,
    "errors": [
      {
        "path": ["name"],
        "message": "Nome é obrigatório"
      }
    ]
  }
}
```

## 📖 Detailed Documentation

Para implementações completas e padrões avançados, consulte:

- **[🛣️ Route Structure](./api/route-structure.md)** - Estrutura e convenções de rotas
- **[📨 Request & Response](./api/request-response.md)** - Padrões de request/response
- **[🔐 Authentication](./api/authentication.md)** - Autenticação e autorização
- **[⚠️ Error Handling](./api/error-handling.md)** - Tratamento de erros
- **[✅ Validation](./api/validation.md)** - Validação com Zod
- **[⚡ Performance](./api/performance.md)** - Otimização e cache

## 🎯 Quick Guidelines

### ✅ Do's

- Sempre usar autenticação
- Validar todos os inputs com Zod
- Implementar soft delete
- Retornar responses padronizadas
- Incluir audit fields
- Tratar erros adequadamente

### ❌ Don'ts

- Nunca deletar fisicamente registros principais
- Não ignorar validação
- Não retornar dados sensíveis
- Não usar status codes incorretos
- Não esquecer de incluir relacionamentos
- Não criar rotas sem autenticação

### **Standard API Route Structure**

```typescript
// app/api/v1/employees/route.ts (Resource operations)
import { NextRequest, NextResponse } from "next/server";

import { getAuthenticatedSession } from "@/lib/api-guard";
import { handleError } from "@/lib/errors/error-handler";
import prisma from "@/lib/prisma";
import { employeeSchema } from "@/services/employees/schemas/employee-schema";

export async function GET() {
  await getAuthenticatedSession();

  try {
    const employees = await prisma.employee.findMany({
      where: {
        status: {
          not: "DELETED",
        },
      },
    });

    return NextResponse.json(employees);
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(request: NextRequest) {
  const session = await getAuthenticatedSession();

  try {
    const body = await request.json();
    const data = employeeSchema.parse(body);

    const employee = await prisma.employee.create({
      data: {
        ...data,
        createdById: session.user.id,
      },
    });

    return NextResponse.json(employee, { status: 201 });
  } catch (error) {
    return handleError(error);
  }
}
```

```typescript
// app/api/v1/employees/[id]/route.ts (Individual resource operations)
import { NextRequest, NextResponse } from "next/server";

import { Status } from "@/generated/prisma";
import { getAuthenticatedSession } from "@/lib/api-guard";
import { NotFoundError } from "@/lib/errors/api-errors";
import { handleError } from "@/lib/errors/error-handler";
import prisma from "@/lib/prisma";
import { employeeSchema } from "@/services/employees/schemas/employee-schema";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  await getAuthenticatedSession();

  const { id } = await params;

  try {
    const employee = await prisma.employee.findUnique({
      where: {
        id,
      },
    });

    if (!employee) {
      throw new NotFoundError("Funcionário não encontrado.");
    }

    return NextResponse.json(employee);
  } catch (error) {
    return handleError(error);
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const session = await getAuthenticatedSession();

  const { id } = await params;

  try {
    const existingEmployee = await prisma.employee.findUnique({
      where: { id },
    });

    if (!existingEmployee) {
      throw new NotFoundError("Funcionário não encontrado.");
    }

    const body = await request.json();
    const data = employeeSchema.parse(body);

    const updatedEmployee = await prisma.employee.update({
      where: { id },
      data: {
        ...data,
        updatedById: session.user.id,
      },
    });

    return NextResponse.json(updatedEmployee);
  } catch (error) {
    return handleError(error);
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const session = await getAuthenticatedSession();

  const { id } = await params;

  try {
    const existingEmployee = await prisma.employee.findUnique({
      where: { id },
    });

    if (!existingEmployee) {
      throw new NotFoundError("Funcionário não encontrado.");
    }

    const updatedEmployee = await prisma.employee.update({
      where: { id },
      data: { status: Status.DELETED, updatedById: session.user.id },
    });

    return NextResponse.json(updatedEmployee);
  } catch (error) {
    return handleError(error);
  }
}
```

```typescript
// app/api/v1/emplooyees/[id]/status/route.ts (Individual resource toggle status operation)
import { NextRequest, NextResponse } from "next/server";

import { Status } from "@/generated/prisma";
import { getAuthenticatedSession } from "@/lib/api-guard";
import { NotFoundError } from "@/lib/errors/api-errors";
import { handleError } from "@/lib/errors/error-handler";
import prisma from "@/lib/prisma";

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const session = await getAuthenticatedSession();

  const { id } = await params;

  try {
    const existingEmployee = await prisma.employee.findUnique({
      where: { id },
    });

    if (!existingEmployee) {
      throw new NotFoundError("Funcionário não encontrado.");
    }

    const newStatus =
      existingEmployee.status === "ACTIVE" ? Status.INACTIVE : Status.ACTIVE;

    const updatedEmployee = await prisma.employee.update({
      where: { id },
      data: {
        status: newStatus,
        updatedById: session.user.id,
      },
    });

    return NextResponse.json(updatedEmployee);
  } catch (error) {
    return handleError(error);
  }
}
```

### **Regra Fundamental**

⚠️ **NUNCA deletar fisicamente registros das entidades principais**

```typescript
// ❌ NUNCA fazer isso
await prisma.supplier.delete({ where: { id } });

// ✅ SEMPRE fazer isso
await prisma.supplier.update({
  where: { id },
  data: {
  status: "DELETED",
  updatedById: userId,
},
```

**Em rotas de criação e atualização sempre validar schema com parse**

```typescript
const body = await request.json();
const data = employeeSchema.parse(body);
```

### **Incluindo Relacionamentos**

```typescript
// Sempre incluir relacionamentos necessários
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
  },
});
```

### **Request/Response Flow**

```
HTTP Request → Route Handler → Service Layer → Data Layer → Database
     ↓              ↓             ↓            ↓           ↓
Query Params → Validation → Business Logic → Repository → Prisma
     ↓              ↓             ↓            ↓           ↓
HTTP Response ← JSON Format ← Service Response ← Data ← Results
```

## 📊 **Error Handling**

### **API Error Response Pattern**

```typescript
// lib/errors/api-error-handler.ts
import { handleApiError } from "@/lib/errors/api-error-handler";

export async function GET(request: Request) {
  try {
    // API logic
    const result = await SomeService.operation();
    return NextResponse.json({ data: result });
  } catch (error) {
    // Delegate to global error handler
    return handleApiError(error);
  }
}
```

### **Standard Error Responses**

```typescript
// Error response format
{
  error: {
    message: string,
    code: string,
    status_code: number,
    errors?: [];
  }
}
```

### **Validation Error Response**

```typescript
// Zod validation error response format
{
  error: {
    message: "Invalid data",
    code: "VALIDATION_ERROR",
    status_code: 422,
      {
        path: ["name"],
        message: "Name is required"
      }
    ]
  }
}
```

## 📖 **Referências Cruzadas**

### **Documentação Relacionada**

- **[04-DATA-PATTERNS.md](./04-DATA-PATTERNS.md)**: Implementação schemas do prisma e relacionamentos
- **[06-SERVICE-PATTERNS.md](./06-DATA-PATTERNS.md)**: Implementação de services, validação e requisições HTTP
- **[08-ERROR-HANDLING.md](./08-ERROR-HANDLING.md)**: Classes de erro, handlers globais, tratamento de exceções
