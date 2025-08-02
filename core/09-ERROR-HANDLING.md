# ⚠️ Avocado HP - Error Handling

## **Filosofia de Error Handling**

### **Princípios Fundamentais**

- **Fail Fast**: Detectar erros o mais cedo possível
- **Graceful Degradation**: Sistema deve continuar funcionando
- **Transparency**: Erros claros para desenvolvedores
- **Security**: Não vazar informações sensíveis
- **Observability**: Logs estruturados para debugging

## **Hierarquia de Erros**

### **Error Classes**

```typescript
// lib/errors/base-error.ts
export abstract class BaseError extends Error {
  abstract statusCode: number;
  abstract code: string;
  abstract isOperational: boolean;

  constructor(
    message: string,
    public context?: Record<string, unknown>,
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

// Business Logic Errors
export class BusinessError extends BaseError {
  statusCode = 400;
  isOperational = true;

  constructor(
    message: string,
    public code: string,
    context?: Record<string, unknown>,
  ) {
    super(message, context);
  }
}

// Validation Errors
export class ValidationError extends BaseError {
  statusCode = 422;
  code = "VALIDATION_ERROR";
  isOperational = true;

  constructor(
    message: string,
    public details: unknown[],
    context?: Record<string, unknown>,
  ) {
    super(message, context);
  }
}

// Authorization Errors
export class AuthorizationError extends BaseError {
  statusCode = 403;
  code = "FORBIDDEN";
  isOperational = true;

  constructor(
    message: string = "Access denied",
    context?: Record<string, unknown>,
  ) {
    super(message, context);
  }
}

// Authentication Errors
export class AuthenticationError extends BaseError {
  statusCode = 401;
  code = "UNAUTHORIZED";
  isOperational = true;

  constructor(
    message: string = "Authentication required",
    context?: Record<string, unknown>,
  ) {
    super(message, context);
  }
}

// Not Found Errors
export class NotFoundError extends BaseError {
  statusCode = 404;
  code = "NOT_FOUND";
  isOperational = true;

  constructor(
    resource: string = "Resource",
    context?: Record<string, unknown>,
  ) {
    super(`${resource} not found`, context);
  }
}

// Rate Limiting Errors
export class RateLimitError extends BaseError {
  statusCode = 429;
  code = "RATE_LIMIT_EXCEEDED";
  isOperational = true;

  constructor(
    message: string = "Rate limit exceeded",
    context?: Record<string, unknown>,
  ) {
    super(message, context);
  }
}

// Internal Errors
export class InternalError extends BaseError {
  statusCode = 500;
  code = "INTERNAL_ERROR";
  isOperational = false;

  constructor(
    message: string = "Internal server error",
    context?: Record<string, unknown>,
  ) {
    super(message, context);
  }
}
```

### **Domain-Specific Errors**

```typescript
// services/suppliers/errors.ts
export class SupplierError extends BusinessError {
  constructor(
    message: string,
    code: string,
    context?: Record<string, unknown>,
  ) {
    super(message, `SUPPLIER_${code}`, context);
  }
}

export class DuplicateSupplierError extends SupplierError {
  constructor(field: string, value: string) {
    super(`Supplier with ${field} '${value}' already exists`, "DUPLICATE", {
      field,
      value,
    });
  }
}

export class InvalidSupplierDataError extends SupplierError {
  constructor(field: string, reason: string) {
    super(`Invalid ${field}: ${reason}`, "INVALID_DATA", { field, reason });
  }
}
```

## **Global Error Handler**

### **API Error Handler**

```typescript
// lib/errors/api-error-handler.ts
import { NextResponse } from "next/server";
import { ZodError } from "zod";
import { Prisma } from "@prisma/client";
import { BaseError } from "./base-error";
import { logger } from "../logger";

export interface ErrorResponse {
  error: {
    message: string;
    code: string;
    statusCode: number;
    details?: unknown;
    timestamp: string;
    requestId?: string;
  };
}

export function handleApiError(
  error: unknown,
  requestId?: string,
): NextResponse<ErrorResponse> {
  const timestamp = new Date().toISOString();

  // Log error for debugging
  logger.error("API Error occurred", error as Error, {
    requestId,
    timestamp,
  });

  // Handle known application errors
  if (error instanceof BaseError) {
    return NextResponse.json(
      {
        error: {
          message: error.message,
          code: error.code,
          statusCode: error.statusCode,
          details: error.context,
          timestamp,
          requestId,
        },
      },
      { status: error.statusCode },
    );
  }

  // Handle Zod validation errors
  if (error instanceof ZodError) {
    return NextResponse.json(
      {
        error: {
          message: "Validation failed",
          code: "VALIDATION_ERROR",
          statusCode: 422,
          details: error.errors,
          timestamp,
          requestId,
        },
      },
      { status: 422 },
    );
  }

  // Handle Prisma database errors
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    const { message, code, statusCode } = handlePrismaError(error);

    return NextResponse.json(
      {
        error: {
          message,
          code,
          statusCode,
          timestamp,
          requestId,
        },
      },
      { status: statusCode },
    );
  }

  // Handle Prisma validation errors
  if (error instanceof Prisma.PrismaClientValidationError) {
    return NextResponse.json(
      {
        error: {
          message: "Database validation error",
          code: "DATABASE_VALIDATION_ERROR",
          statusCode: 400,
          timestamp,
          requestId,
        },
      },
      { status: 400 },
    );
  }

  // Handle unexpected errors
  logger.error("Unexpected error", error as Error, {
    requestId,
    timestamp,
    type: "UNEXPECTED_ERROR",
  });

  return NextResponse.json(
    {
      error: {
        message: "Internal server error",
        code: "INTERNAL_ERROR",
        statusCode: 500,
        timestamp,
        requestId,
      },
    },
    { status: 500 },
  );
}

function handlePrismaError(error: Prisma.PrismaClientKnownRequestError) {
  switch (error.code) {
    case "P2002":
      return {
        message: "Record already exists",
        code: "DUPLICATE_ENTRY",
        statusCode: 409,
      };
    case "P2025":
      return {
        message: "Record not found",
        code: "NOT_FOUND",
        statusCode: 404,
      };
    case "P2003":
      return {
        message: "Foreign key constraint failed",
        code: "FOREIGN_KEY_CONSTRAINT",
        statusCode: 400,
      };
    case "P2014":
      return {
        message: "Invalid ID provided",
        code: "INVALID_ID",
        statusCode: 400,
      };
    default:
      return {
        message: "Database error",
        code: "DATABASE_ERROR",
        statusCode: 500,
      };
  }
}
```

### **Error Boundary para React**

```typescript
// components/error-boundary.tsx
"use client"

import React from 'react'
import { logger } from '@/lib/logger'

interface Props {
  children: React.ReactNode
  fallback?: React.ComponentType<{ error: Error; reset: () => void }>
}

interface State {
  hasError: boolean
  error?: Error
}

export class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    logger.error('React Error Boundary caught error', error, {
      componentStack: errorInfo.componentStack,
      errorBoundary: true
    })
  }

  render() {
    if (this.state.hasError) {
      const Fallback = this.props.fallback || DefaultErrorFallback

      return (
        <Fallback
          error={this.state.error!}
          reset={() => this.setState({ hasError: false, error: undefined })}
        />
      )
    }

    return this.props.children
  }
}

function DefaultErrorFallback({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] p-6">
      <div className="text-center space-y-4">
        <h2 className="text-2xl font-bold text-destructive">
          Algo deu errado
        </h2>
        <p className="text-muted-foreground max-w-md">
          Ocorreu um erro inesperado. Nossa equipe foi notificada.
        </p>
        <div className="flex gap-4">
          <button
            onClick={reset}
            className="px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
          >
            Tentar novamente
          </button>
          <button
            onClick={() => window.location.reload()}
            className="px-4 py-2 border border-input bg-background hover:bg-accent rounded-md"
          >
            Recarregar página
          </button>
        </div>
      </div>
    </div>
  )
}
```

## **API Route Error Handling**

### **Wrapper Function**

```typescript
// lib/errors/with-error-handling.ts
import { NextRequest, NextResponse } from "next/server";
import { handleApiError } from "./api-error-handler";

type ApiHandler = (
  request: NextRequest,
  context?: { params: Record<string, string> },
) => Promise<NextResponse>;

export function withErrorHandling(handler: ApiHandler): ApiHandler {
  return async (request, context) => {
    const requestId = crypto.randomUUID();

    try {
      // Add request ID to headers for tracking
      const response = await handler(request, context);
      response.headers.set("X-Request-ID", requestId);
      return response;
    } catch (error) {
      return handleApiError(error, requestId);
    }
  };
}
```

### **Usage in API Routes**

```typescript
// app/api/v1/suppliers/route.ts
import { withErrorHandling } from "@/lib/errors/with-error-handling";
import { SupplierService } from "@/services/suppliers";
import { NotFoundError, ValidationError } from "@/lib/errors/base-error";

async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "10");

  if (page < 1 || limit < 1 || limit > 100) {
    throw new ValidationError("Invalid pagination parameters", [
      { message: "Page must be >= 1 and limit must be between 1 and 100" },
    ]);
  }

  const suppliers = await SupplierService.findMany({ page, limit });

  return NextResponse.json({ data: suppliers });
}

async function POST(request: NextRequest) {
  const body = await request.json();
  const session = await requireAuth(request);

  const supplier = await SupplierService.create(body, session.user.id);

  return NextResponse.json(
    { data: supplier, message: "Supplier created successfully" },
    { status: 201 },
  );
}

// Export wrapped handlers
export const GET = withErrorHandling(GET);
export const POST = withErrorHandling(POST);
```

## **Client-Side Error Handling**

### **React Query Error Handling**

```typescript
// hooks/use-error-handler.ts
import { useCallback } from "react";
import { toast } from "sonner";

export function useErrorHandler() {
  const handleError = useCallback((error: unknown) => {
    if (error instanceof Error) {
      // Check if it's an API error response
      if ("response" in error && error.response) {
        const apiError = error.response as {
          data: { error: { message: string; code: string } };
        };

        switch (apiError.data.error.code) {
          case "UNAUTHORIZED":
            toast.error("Sessão expirada. Faça login novamente.");
            window.location.href = "/login";
            break;
          case "FORBIDDEN":
            toast.error("Você não tem permissão para esta ação.");
            break;
          case "VALIDATION_ERROR":
            toast.error("Dados inválidos. Verifique os campos.");
            break;
          case "NOT_FOUND":
            toast.error("Recurso não encontrado.");
            break;
          default:
            toast.error(apiError.data.error.message || "Erro inesperado");
        }
      } else {
        toast.error("Erro de conexão. Verifique sua internet.");
      }
    } else {
      toast.error("Erro inesperado.");
    }
  }, []);

  return { handleError };
}
```

### **Global Query Error Handler**

```typescript
// lib/react-query.ts
import { QueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        // Don't retry on 4xx errors
        if (error && "status" in error && typeof error.status === "number") {
          return error.status >= 500 && failureCount < 3;
        }
        return failureCount < 3;
      },
      onError: (error) => {
        console.error("Query error:", error);
        // Global error toast handled by individual hooks
      },
    },
    mutations: {
      onError: (error) => {
        console.error("Mutation error:", error);
        // Let individual mutations handle their errors
      },
    },
  },
});
```

## **Monitoring e Alertas**

### **Error Metrics**

```typescript
// lib/errors/error-metrics.ts
import { Counter, Histogram } from "prom-client";

export const errorCounter = new Counter({
  name: "avocado_hp_errors_total",
  help: "Total number of errors",
  labelNames: ["type", "code", "endpoint", "method"],
});

export const errorDuration = new Histogram({
  name: "avocado_hp_error_duration_seconds",
  help: "Duration until error occurred",
  labelNames: ["type", "code"],
  buckets: [0.1, 0.5, 1, 2, 5, 10],
});

export function recordError(
  type: string,
  code: string,
  endpoint?: string,
  method?: string,
  duration?: number,
) {
  errorCounter.inc({
    type,
    code,
    endpoint: endpoint || "unknown",
    method: method || "unknown",
  });

  if (duration) {
    errorDuration.observe({ type, code }, duration);
  }
}
```

### **Error Alerting**

```typescript
// lib/errors/error-alerting.ts
import { logger } from "../logger";

export class ErrorAlerting {
  static async notifyCriticalError(
    error: BaseError,
    context: Record<string, unknown>,
  ) {
    if (!error.isOperational) {
      logger.error("Critical error detected", error, {
        ...context,
        alertLevel: "critical",
        requiresAttention: true,
      });

      // In production, send to external alerting service
      if (process.env.NODE_ENV === "production") {
        await this.sendAlert({
          level: "critical",
          message: error.message,
          stack: error.stack,
          context,
        });
      }
    }
  }

  private static async sendAlert(alert: {
    level: string;
    message: string;
    stack?: string;
    context: Record<string, unknown>;
  }) {
    // Implementation for external alerting service
    // e.g., PagerDuty, Slack, Discord, etc.
  }
}
```

## **Error Prevention**

### **Input Sanitization**

```typescript
// lib/sanitization.ts
import DOMPurify from "isomorphic-dompurify";

export function sanitizeInput(input: string): string {
  return DOMPurify.sanitize(input, { ALLOWED_TAGS: [] });
}

export function sanitizeObject<T extends Record<string, unknown>>(obj: T): T {
  const sanitized = {} as T;

  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === "string") {
      sanitized[key as keyof T] = sanitizeInput(value) as T[keyof T];
    } else {
      sanitized[key as keyof T] = value as T[keyof T];
    }
  }

  return sanitized;
}
```

### **Rate Limiting**

```typescript
// lib/rate-limiting.ts (future implementation)
import { NextRequest } from "next/server";
import { RateLimitError } from "./errors/base-error";

const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

export function checkRateLimit(
  request: NextRequest,
  limit: number = 100,
  windowMs: number = 60000, // 1 minute
) {
  const identifier = request.ip || "anonymous";
  const now = Date.now();

  const current = rateLimitStore.get(identifier);

  if (!current || now > current.resetTime) {
    rateLimitStore.set(identifier, {
      count: 1,
      resetTime: now + windowMs,
    });
    return;
  }

  if (current.count >= limit) {
    throw new RateLimitError("Rate limit exceeded. Try again later.");
  }

  current.count++;
}
```

## **Debugging Tools**

### **Error Context Collector**

```typescript
// lib/errors/error-context.ts
export class ErrorContext {
  private static context: Record<string, unknown> = {};

  static set(key: string, value: unknown) {
    this.context[key] = value;
  }

  static get(key: string) {
    return this.context[key];
  }

  static getAll() {
    return { ...this.context };
  }

  static clear() {
    this.context = {};
  }
}

// Usage in API routes
ErrorContext.set("userId", session.user.id);
ErrorContext.set("endpoint", request.url);
ErrorContext.set("userAgent", request.headers.get("user-agent"));
```

### **Development Error Page**

```typescript
// app/error.tsx (Next.js 13+)
'use client'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  const isDevelopment = process.env.NODE_ENV === 'development'

  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-6">
      <div className="max-w-2xl w-full space-y-6">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-destructive mb-2">
            Erro na Aplicação
          </h1>
          <p className="text-muted-foreground">
            Algo deu errado. Nossa equipe foi notificada.
          </p>
        </div>

        {isDevelopment && (
          <div className="bg-muted p-4 rounded-lg">
            <h3 className="font-semibold mb-2">Debug Info:</h3>
            <pre className="text-sm overflow-auto">
              {error.message}
              {error.stack}
            </pre>
          </div>
        )}

        <div className="flex justify-center gap-4">
          <button
            onClick={reset}
            className="px-6 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
          >
            Tentar Novamente
          </button>
          <a
            href="/"
            className="px-6 py-2 border border-input bg-background hover:bg-accent rounded-md"
          >
            Voltar ao Início
          </a>
        </div>
      </div>
    </div>
  )
}
```

## 📖 **Referências Cruzadas**

### **Documentação Relacionada**

- **[06-API-PATTERNS.md](./06-API-PATTERNS.md)**: Integração de error handlers com API routes
- **[07-DATA-PATTERNS.md](./07-DATA-PATTERNS.md)**: Erros de validação e transações Prisma
- **[02-ARCHITECTURE.md](./02-ARCHITECTURE.md)**: Error Boundaries e tratamento client-side

### **Integração entre Arquivos**

1. **Error Classes** (este arquivo) → define tipos de erro
2. **API Handlers** → usam classes para API routes (**API-PATTERNS**)
3. **Data Validation** → aplica em schemas Zod (**DATA-PATTERNS**)
4. **Frontend** → Error Boundaries para React (**ARCHITECTURE**)

### **Fluxo de Error Handling**

```
Error Source → Error Class → Handler → Log → Response
     ↓            ↓          ↓        ↓        ↓
  Validation   BaseError   Global   Logger   HTTP
  Database     Domain      API      Console  Client
  Business     Custom      React    External UI
```

### **Estratégia de Debugging**

- **Development**: Stack traces completos, error pages detalhados
- **Production**: Logs estruturados, alertas automáticos, mensagens sanitizadas
- **Monitoring**: Métricas de erro, rate limiting, performance tracking
