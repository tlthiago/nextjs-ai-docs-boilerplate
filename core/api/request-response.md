# Request & Response Patterns

## 📨 Request Format

### Required Headers

```typescript
{
  'Content-Type': 'application/json',
  'Cookie': 'better-auth.session_token=...'  // Better Auth session
}
```

### Request Body Validation

```typescript
// Always validate request body with Zod
const body = await request.json();
const data = resourceSchema.parse(body);
```

## 📤 Response Format Standards

### Success Response Format

#### Single Resource (200, 201)

```typescript
{
  data: T,                    // The resource data
  message?: string           // Optional success message
}
```

#### Multiple Resources (200)

```typescript
{
  data: T[],                 // Array of resources
  meta?: {                   // Pagination metadata
    page: number,
    limit: number,
    total: number,
    totalPages: number
  },
  message?: string
}
```

### Error Response Format

```typescript
{
  error: {
    message: string,         // Human-readable error message
    code: string,           // Error code for client handling
    statusCode: number,     // HTTP status code
    errors?: Array<{        // Validation errors (Zod)
      path: string[],
      message: string
    }>
  }
}
```

## 🎯 HTTP Status Codes

### Success Codes

- **200 OK** - GET, PATCH, DELETE operations
- **201 Created** - POST operations (resource creation)

### Client Error Codes

- **400 Bad Request** - Malformed request data
- **401 Unauthorized** - Authentication required/failed
- **403 Forbidden** - Authenticated but no permission
- **404 Not Found** - Resource not found
- **422 Unprocessable Entity** - Validation failed (Zod)

### Server Error Codes

- **500 Internal Server Error** - Unexpected server error

## 📋 Response Examples

### Successful Creation (201)

```typescript
// POST /api/v1/employees
{
  "data": {
    "id": "clx1234567890",
    "name": "João Silva",
    "email": "joao@empresa.com",
    "role": "MANAGER",
    "status": "ACTIVE",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z",
    "createdById": "user123"
  },
  "message": "Funcionário criado com sucesso"
}
```

### Successful List (200)

```typescript
// GET /api/v1/employees?page=1&limit=10
{
  "data": [
    {
      "id": "clx1234567890",
      "name": "João Silva",
      "email": "joao@empresa.com",
      "role": "MANAGER",
      "status": "ACTIVE"
    },
    {
      "id": "clx0987654321",
      "name": "Maria Santos",
      "email": "maria@empresa.com",
      "role": "OPERATOR",
      "status": "ACTIVE"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "totalPages": 3
  }
}
```

### Successful Update (200)

```typescript
// PATCH /api/v1/employees/clx1234567890
{
  "data": {
    "id": "clx1234567890",
    "name": "João Silva Santos",
    "email": "joao.santos@empresa.com",
    "role": "SENIOR_MANAGER",
    "status": "ACTIVE",
    "updatedAt": "2024-01-15T14:20:00Z",
    "updatedById": "user456"
  },
  "message": "Funcionário atualizado com sucesso"
}
```

### Status Toggle (200)

```typescript
// PATCH /api/v1/employees/clx1234567890/status
{
  "data": {
    "id": "clx1234567890",
    "name": "João Silva",
    "status": "INACTIVE",
    "updatedAt": "2024-01-15T15:00:00Z",
    "updatedById": "user456"
  },
  "message": "Status inativo aplicado com sucesso"
}
```

### Soft Delete (200)

```typescript
// DELETE /api/v1/employees/clx1234567890
{
  "data": {
    "id": "clx1234567890",
    "name": "João Silva",
    "status": "DELETED",
    "updatedAt": "2024-01-15T16:00:00Z",
    "updatedById": "user456"
  },
  "message": "Funcionário excluído com sucesso"
}
```

## ❌ Error Response Examples

### Validation Error (422)

```typescript
// POST /api/v1/employees (invalid data)
{
  "error": {
    "message": "Dados inválidos",
    "code": "VALIDATION_ERROR",
    "statusCode": 422,
    "errors": [
      {
        "path": ["name"],
        "message": "Nome é obrigatório"
      },
      {
        "path": ["email"],
        "message": "Email inválido"
      }
    ]
  }
}
```

### Not Found Error (404)

```typescript
// GET /api/v1/employees/invalid-id
{
  "error": {
    "message": "Funcionário não encontrado",
    "code": "NOT_FOUND",
    "statusCode": 404
  }
}
```

### Unauthorized Error (401)

```typescript
// Any request without valid session
{
  "error": {
    "message": "Acesso não autorizado",
    "code": "UNAUTHORIZED",
    "statusCode": 401
  }
}
```

### Server Error (500)

```typescript
// Unexpected server error
{
  "error": {
    "message": "Erro interno do servidor",
    "code": "INTERNAL_SERVER_ERROR",
    "statusCode": 500
  }
}
```

## 🔧 Response Implementation Pattern

### Success Response Helper

```typescript
// lib/api/response.ts
export function successResponse<T>(
  data: T,
  message?: string,
  status: number = 200,
) {
  return NextResponse.json({ data, message }, { status });
}

export function paginatedResponse<T>(
  data: T[],
  meta: PaginationMeta,
  message?: string,
) {
  return NextResponse.json({
    data,
    meta,
    message,
  });
}

// Usage in routes
return successResponse(employee, "Funcionário criado", 201);
return paginatedResponse(employees, paginationMeta);
```

### Pagination Metadata

```typescript
interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

function createPaginationMeta(
  page: number,
  limit: number,
  total: number,
): PaginationMeta {
  return {
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit),
  };
}
```

## 🎯 Best Practices

### ✅ Do's

- Sempre retornar formato consistente
- Incluir messages apropriadas
- Usar status codes corretos
- Implementar paginação para listas
- Validar todos os inputs
- Incluir metadata útil

### ❌ Don'ts

- Não retornar formatos inconsistentes
- Não expor dados sensíveis
- Não usar status codes incorretos
- Não ignorar validation errors
- Não retornar stacks traces em produção
- Não esquecer de incluir mensagens de sucesso
