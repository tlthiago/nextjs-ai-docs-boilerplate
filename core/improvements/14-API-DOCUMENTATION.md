# 📚 API Documentation - Avocado HP

## **Filosofia de Documentação**

### **Princípios**

- **Auto-documentação**: Código que se documenta através de tipos
- **OpenAPI/Swagger**: Especificação padrão da indústria
- **Contract Testing**: Garantir que implementação segue documentação
- **Versionamento**: Documentação versionada junto com API
- **Exemplos Práticos**: Cada endpoint com exemplos reais

## **OpenAPI/Swagger Integration**

### **Configuração Base**

```typescript
// lib/swagger/config.ts
import { createSwaggerSpec } from "next-swagger-doc";

export const getApiDocs = async () => {
  const spec = createSwaggerSpec({
    apiFolder: "src/app/api",
    definition: {
      openapi: "3.0.0",
      info: {
        title: "Avocado HP API",
        version: "1.0.0",
        description: "Farm Management System API - Sistema de Gestão Agrícola",
        contact: {
          name: "Development Team",
          email: "dev@avocado-hp.com",
        },
        license: {
          name: "Private",
          url: "https://avocado-hp.com/license",
        },
      },
      servers: [
        {
          url: process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000",
          description: "Development server",
        },
        {
          url: "https://api.avocado-hp.com",
          description: "Production server",
        },
      ],
      components: {
        securitySchemes: {
          BetterAuth: {
            type: "apiKey",
            in: "cookie",
            name: "better-auth.session_token",
            description: "Better Auth session cookie",
          },
        },
        schemas: {
          Error: {
            type: "object",
            required: ["error"],
            properties: {
              error: {
                type: "object",
                required: ["message", "code", "statusCode", "timestamp"],
                properties: {
                  message: {
                    type: "string",
                    description: "Human-readable error message",
                  },
                  code: {
                    type: "string",
                    description: "Machine-readable error code",
                  },
                  statusCode: {
                    type: "number",
                    description: "HTTP status code",
                  },
                  details: {
                    type: "object",
                    description: "Additional error details",
                  },
                  timestamp: {
                    type: "string",
                    format: "date-time",
                    description: "Error timestamp in ISO format",
                  },
                  requestId: {
                    type: "string",
                    description: "Unique request identifier for tracking",
                  },
                },
              },
            },
          },
          Pagination: {
            type: "object",
            required: ["page", "limit", "total", "totalPages"],
            properties: {
              page: {
                type: "integer",
                minimum: 1,
                description: "Current page number",
              },
              limit: {
                type: "integer",
                minimum: 1,
                maximum: 100,
                description: "Items per page",
              },
              total: {
                type: "integer",
                minimum: 0,
                description: "Total number of items",
              },
              totalPages: {
                type: "integer",
                minimum: 0,
                description: "Total number of pages",
              },
            },
          },
        },
      },
      security: [{ BetterAuth: [] }],
      tags: [
        {
          name: "Authentication",
          description: "User authentication and session management",
        },
        {
          name: "Machineries",
          description: "Farm machinery and equipment management",
        },
        {
          name: "Implements",
          description: "Agricultural implements management",
        },
        {
          name: "Employees",
          description: "Employee management",
        },
        {
          name: "Control Units",
          description: "Property control units management",
        },
        {
          name: "Suppliers",
          description: "Supplier management",
        },
      ],
    },
  });

  return spec;
};
```

### **Swagger UI Page**

```typescript
// app/api-docs/page.tsx
import { getApiDocs } from '@/lib/swagger/config'
import SwaggerUI from 'swagger-ui-react'
import 'swagger-ui-react/swagger-ui.css'

export default async function ApiDocsPage() {
  const spec = await getApiDocs()

  return (
    <div className="min-h-screen">
      <div className="container mx-auto py-8">
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-4">Avocado HP API Documentation</h1>
          <p className="text-lg text-muted-foreground">
            Complete API reference for the Farm Management System
          </p>
        </div>

        <SwaggerUI
          spec={spec}
          docExpansion="list"
          defaultModelsExpandDepth={2}
          defaultModelExpandDepth={2}
          tryItOutEnabled={true}
        />
      </div>
    </div>
  )
}
```

## **JSDoc Comments for API Routes**

### **Padrão de Documentação**

```typescript
/**
 * @swagger
 * /api/v1/properties/machineries:
 *   get:
 *     summary: List all machineries
 *     description: |
 *       Retrieve a paginated list of machineries with optional filtering.
 *       Supports search by name, filtering by type and status.
 *     tags: [Machineries]
 *     security:
 *       - BetterAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         required: false
 *         schema:
 *           type: integer
 *           minimum: 1
 *           default: 1
 *         description: Page number for pagination
 *         example: 1
 *       - in: query
 *         name: limit
 *         required: false
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 100
 *           default: 10
 *         description: Number of items per page
 *         example: 10
 *       - in: query
 *         name: search
 *         required: false
 *         schema:
 *           type: string
 *           minLength: 1
 *         description: Search term for machinery name (case-insensitive)
 *         example: "tractor"
 *       - in: query
 *         name: type
 *         required: false
 *         schema:
 *           type: string
 *           enum: [TRACTOR, SPRAYER, CHAINSAW, VEHICLE]
 *         description: Filter by machinery type
 *         example: "TRACTOR"
 *       - in: query
 *         name: status
 *         required: false
 *         schema:
 *           type: string
 *           enum: [ACTIVE, INACTIVE, MAINTENANCE]
 *         description: Filter by machinery status (excludes DELETED)
 *         example: "ACTIVE"
 *       - in: query
 *         name: orderBy
 *         required: false
 *         schema:
 *           type: string
 *           enum: [name, type, hourlyRate, createdAt, updatedAt]
 *           default: createdAt
 *         description: Field to order by
 *         example: "name"
 *       - in: query
 *         name: orderDir
 *         required: false
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *           default: desc
 *         description: Order direction
 *         example: "asc"
 *     responses:
 *       200:
 *         description: List of machineries retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Machinery'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 *                 message:
 *                   type: string
 *                   example: "Machineries retrieved successfully"
 *             examples:
 *               success:
 *                 value:
 *                   data:
 *                     - id: "cm123abc"
 *                       name: "John Deere 6120"
 *                       type: "TRACTOR"
 *                       hourlyRate: 150.00
 *                       status: "ACTIVE"
 *                       createdAt: "2025-01-15T10:30:00Z"
 *                       updatedAt: "2025-01-15T10:30:00Z"
 *                       createdById: "user123"
 *                   pagination:
 *                     page: 1
 *                     limit: 10
 *                     total: 25
 *                     totalPages: 3
 *       401:
 *         description: Unauthorized - Session required
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             examples:
 *               unauthorized:
 *                 value:
 *                   error:
 *                     message: "Authentication required"
 *                     code: "UNAUTHORIZED"
 *                     statusCode: 401
 *                     timestamp: "2025-01-15T10:30:00Z"
 *       422:
 *         description: Validation Error - Invalid query parameters
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *   post:
 *     summary: Create new machinery
 *     description: |
 *       Create a new machinery record with audit tracking.
 *       All required fields must be provided.
 *     tags: [Machineries]
 *     security:
 *       - BetterAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateMachineryRequest'
 *           examples:
 *             tractor:
 *               summary: "New Tractor"
 *               value:
 *                 name: "John Deere 6130"
 *                 type: "TRACTOR"
 *                 hourlyRate: 175.50
 *                 description: "Heavy-duty tractor for field work"
 *             sprayer:
 *               summary: "New Sprayer"
 *               value:
 *                 name: "Case IH FLX3520"
 *                 type: "SPRAYER"
 *                 hourlyRate: 120.00
 *                 description: "Self-propelled sprayer"
 *     responses:
 *       201:
 *         description: Machinery created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/Machinery'
 *                 message:
 *                   type: string
 *                   example: "Machinery created successfully"
 *       422:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             examples:
 *               validation_error:
 *                 value:
 *                   error:
 *                     message: "Validation failed"
 *                     code: "VALIDATION_ERROR"
 *                     statusCode: 422
 *                     details:
 *                       - path: ["name"]
 *                         message: "Name is required"
 *                       - path: ["hourlyRate"]
 *                         message: "Hourly rate must be positive"
 *                     timestamp: "2025-01-15T10:30:00Z"
 */
export async function GET(request: NextRequest) {
  // Implementation
}
```

## **Schema Definitions**

### **Core Entity Schemas**

```typescript
// lib/swagger/schemas.ts
export const machinerySchema = {
  type: "object",
  required: [
    "id",
    "name",
    "type",
    "hourlyRate",
    "status",
    "createdAt",
    "updatedAt",
    "createdById",
  ],
  properties: {
    id: {
      type: "string",
      description: "Unique machinery identifier",
      example: "cm123abc",
    },
    name: {
      type: "string",
      minLength: 1,
      maxLength: 255,
      description: "Machinery name",
      example: "John Deere 6120",
    },
    type: {
      type: "string",
      enum: ["TRACTOR", "SPRAYER", "CHAINSAW", "VEHICLE"],
      description: "Type of machinery",
      example: "TRACTOR",
    },
    hourlyRate: {
      type: "number",
      minimum: 0,
      multipleOf: 0.01,
      description: "Hourly rental rate in currency units",
      example: 150.0,
    },
    description: {
      type: "string",
      nullable: true,
      maxLength: 1000,
      description: "Optional machinery description",
      example: "Heavy-duty tractor for field operations",
    },
    status: {
      type: "string",
      enum: ["ACTIVE", "INACTIVE", "MAINTENANCE", "DELETED"],
      description: "Current machinery status",
      example: "ACTIVE",
    },
    createdAt: {
      type: "string",
      format: "date-time",
      description: "Creation timestamp",
      example: "2025-01-15T10:30:00Z",
    },
    updatedAt: {
      type: "string",
      format: "date-time",
      description: "Last update timestamp",
      example: "2025-01-15T10:30:00Z",
    },
    createdById: {
      type: "string",
      description: "ID of user who created the record",
      example: "user123",
    },
    updatedById: {
      type: "string",
      nullable: true,
      description: "ID of user who last updated the record",
      example: "user456",
    },
  },
};

export const createMachineryRequestSchema = {
  type: "object",
  required: ["name", "type", "hourlyRate"],
  properties: {
    name: machinerySchema.properties.name,
    type: machinerySchema.properties.type,
    hourlyRate: machinerySchema.properties.hourlyRate,
    description: machinerySchema.properties.description,
  },
};

export const updateMachineryRequestSchema = {
  type: "object",
  properties: {
    name: machinerySchema.properties.name,
    type: machinerySchema.properties.type,
    hourlyRate: machinerySchema.properties.hourlyRate,
    description: machinerySchema.properties.description,
    status: {
      type: "string",
      enum: ["ACTIVE", "INACTIVE", "MAINTENANCE"], // Exclude DELETED
      description: "Machinery status (cannot set to DELETED)",
      example: "ACTIVE",
    },
  },
};
```

### **Response Type Definitions**

```typescript
// types/api-docs.ts
export interface ApiResponse<T> {
  data: T;
  message?: string;
}

export interface PaginatedApiResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

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

// Swagger schema exports
export interface SwaggerSchemas {
  // Machinery
  Machinery: {
    id: string;
    name: string;
    type: "TRACTOR" | "SPRAYER" | "CHAINSAW" | "VEHICLE";
    hourlyRate: number;
    description?: string;
    status: "ACTIVE" | "INACTIVE" | "MAINTENANCE" | "DELETED";
    createdAt: string;
    updatedAt: string;
    createdById: string;
    updatedById?: string;
  };

  CreateMachineryRequest: {
    name: string;
    type: "TRACTOR" | "SPRAYER" | "CHAINSAW" | "VEHICLE";
    hourlyRate: number;
    description?: string;
  };

  UpdateMachineryRequest: {
    name?: string;
    type?: "TRACTOR" | "SPRAYER" | "CHAINSAW" | "VEHICLE";
    hourlyRate?: number;
    description?: string;
    status?: "ACTIVE" | "INACTIVE" | "MAINTENANCE";
  };

  // Employee
  Employee: {
    id: string;
    name: string;
    email: string;
    phone?: string;
    role: "MANAGER" | "OPERATOR" | "TECHNICIAN" | "ADMINISTRATOR";
    hourlyRate: number;
    status: "ACTIVE" | "INACTIVE" | "DELETED";
    createdAt: string;
    updatedAt: string;
    createdById: string;
    updatedById?: string;
  };

  // Supplier
  Supplier: {
    id: string;
    name: string;
    email?: string;
    phone?: string;
    address?: string;
    cnpj?: string;
    status: "ACTIVE" | "INACTIVE" | "DELETED";
    categories: SupplierCategory[];
    createdAt: string;
    updatedAt: string;
    createdById: string;
    updatedById?: string;
  };

  SupplierCategory: {
    id: string;
    name: string;
    description?: string;
    status: "ACTIVE" | "INACTIVE" | "DELETED";
    createdAt: string;
    updatedAt: string;
    createdById: string;
    updatedById?: string;
  };

  // Implement
  Implement: {
    id: string;
    name: string;
    type: "PLOW" | "HARROW" | "SEEDER" | "CULTIVATOR" | "MOWER" | "OTHER";
    hourlyRate: number;
    description?: string;
    status: "ACTIVE" | "INACTIVE" | "MAINTENANCE" | "DELETED";
    createdAt: string;
    updatedAt: string;
    createdById: string;
    updatedById?: string;
  };

  // Control Unit
  ControlUnit: {
    id: string;
    name: string;
    location?: string;
    area?: number;
    description?: string;
    status: "ACTIVE" | "INACTIVE" | "DELETED";
    createdAt: string;
    updatedAt: string;
    createdById: string;
    updatedById?: string;
  };

  // Pagination
  Pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
```

## **API Testing with Documentation**

### **Contract Testing**

```typescript
// __tests__/api/contract.test.ts
import { validateApiResponse } from "@/__tests__/helpers/schema-validator";
import { SwaggerSchemas } from "@/types/api-docs";

describe("API Contract Tests", () => {
  describe("Machinery API", () => {
    it("should match expected response schema for machinery list", async () => {
      const response = await fetch("/api/v1/properties/machineries", {
        headers: { Cookie: authCookie },
      });

      expect(response.status).toBe(200);
      const data = await response.json();

      // Validate structure
      expect(data).toHaveProperty("data");
      expect(data).toHaveProperty("pagination");
      expect(Array.isArray(data.data)).toBe(true);

      // Validate pagination structure
      expect(data.pagination).toMatchObject({
        page: expect.any(Number),
        limit: expect.any(Number),
        total: expect.any(Number),
        totalPages: expect.any(Number),
      });

      // Validate individual machinery objects
      if (data.data.length > 0) {
        const machinery = data.data[0];
        expect(machinery).toMatchObject({
          id: expect.any(String),
          name: expect.any(String),
          type: expect.stringMatching(/^(TRACTOR|SPRAYER|CHAINSAW|VEHICLE)$/),
          hourlyRate: expect.any(Number),
          status: expect.stringMatching(/^(ACTIVE|INACTIVE|MAINTENANCE)$/),
          createdAt: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/),
          updatedAt: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/),
          createdById: expect.any(String),
        });
      }
    });

    it("should return consistent error format for invalid requests", async () => {
      const response = await fetch(
        "/api/v1/properties/machineries/invalid-id",
        {
          headers: { Cookie: authCookie },
        },
      );

      expect(response.status).toBe(404);
      const data = await response.json();

      expect(data).toMatchObject({
        error: {
          message: expect.any(String),
          code: expect.any(String),
          statusCode: expect.any(Number),
          timestamp: expect.stringMatching(/^\d{4}-\d{2}-\d{2}T/),
        },
      });
    });

    it("should validate POST request body schema", async () => {
      const invalidData = {
        name: "", // Invalid: empty string
        type: "INVALID_TYPE", // Invalid: not in enum
        hourlyRate: -10, // Invalid: negative
      };

      const response = await fetch("/api/v1/properties/machineries", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Cookie: authCookie,
        },
        body: JSON.stringify(invalidData),
      });

      expect(response.status).toBe(422);
      const data = await response.json();

      expect(data.error.code).toBe("VALIDATION_ERROR");
      expect(data.error.details).toHaveLength(3);
      expect(data.error.details[0]).toHaveProperty("path");
      expect(data.error.details[0]).toHaveProperty("message");
    });
  });
});
```

### **Schema Validation Helper**

```typescript
// __tests__/helpers/schema-validator.ts
import Ajv from "ajv";
import addFormats from "ajv-formats";
import { SwaggerSchemas } from "@/types/api-docs";

const ajv = new Ajv({ allErrors: true });
addFormats(ajv);

// Define schemas for validation
const schemas = {
  Machinery: {
    type: "object",
    required: [
      "id",
      "name",
      "type",
      "hourlyRate",
      "status",
      "createdAt",
      "updatedAt",
      "createdById",
    ],
    properties: {
      id: { type: "string" },
      name: { type: "string", minLength: 1 },
      type: {
        type: "string",
        enum: ["TRACTOR", "SPRAYER", "CHAINSAW", "VEHICLE"],
      },
      hourlyRate: { type: "number", minimum: 0 },
      description: { type: ["string", "null"] },
      status: {
        type: "string",
        enum: ["ACTIVE", "INACTIVE", "MAINTENANCE", "DELETED"],
      },
      createdAt: { type: "string", format: "date-time" },
      updatedAt: { type: "string", format: "date-time" },
      createdById: { type: "string" },
      updatedById: { type: ["string", "null"] },
    },
    additionalProperties: false,
  },

  PaginatedMachineryResponse: {
    type: "object",
    required: ["data", "pagination"],
    properties: {
      data: {
        type: "array",
        items: { $ref: "#/schemas/Machinery" },
      },
      pagination: {
        type: "object",
        required: ["page", "limit", "total", "totalPages"],
        properties: {
          page: { type: "number", minimum: 1 },
          limit: { type: "number", minimum: 1, maximum: 100 },
          total: { type: "number", minimum: 0 },
          totalPages: { type: "number", minimum: 0 },
        },
      },
      message: { type: "string" },
    },
    additionalProperties: false,
  },
};

// Compile schemas
Object.entries(schemas).forEach(([name, schema]) => {
  ajv.addSchema(schema, `#/schemas/${name}`);
});

export function validateApiResponse(
  data: unknown,
  schemaName: keyof typeof schemas,
): boolean {
  const validate = ajv.getSchema(`#/schemas/${schemaName}`);
  if (!validate) {
    throw new Error(`Schema ${schemaName} not found`);
  }

  const valid = validate(data);
  if (!valid) {
    console.error("Validation errors:", validate.errors);
    return false;
  }

  return true;
}

export function getValidationErrors(
  data: unknown,
  schemaName: keyof typeof schemas,
) {
  const validate = ajv.getSchema(`#/schemas/${schemaName}`);
  if (!validate) {
    throw new Error(`Schema ${schemaName} not found`);
  }

  validate(data);
  return validate.errors;
}
```

## **API Documentation Generation**

### **Automated Documentation Build**

```typescript
// scripts/generate-api-docs.ts
import fs from "fs/promises";
import path from "path";
import { getApiDocs } from "@/lib/swagger/config";

async function generateApiDocs() {
  try {
    console.log("🚀 Generating API documentation...");

    // Generate OpenAPI spec
    const spec = await getApiDocs();

    // Save to public directory
    const publicDir = path.join(process.cwd(), "public");
    const specPath = path.join(publicDir, "api-spec.json");

    await fs.writeFile(specPath, JSON.stringify(spec, null, 2));

    console.log("✅ API documentation generated successfully!");
    console.log(`📄 OpenAPI spec saved to: ${specPath}`);
    console.log("🌐 View at: http://localhost:3000/api-docs");

    // Generate TypeScript types from OpenAPI spec
    await generateTypesFromSpec(spec);
  } catch (error) {
    console.error("❌ Failed to generate API documentation:", error);
    process.exit(1);
  }
}

async function generateTypesFromSpec(spec: any) {
  // Implementation for generating TypeScript types from OpenAPI spec
  // Could use tools like openapi-typescript
  console.log("📝 TypeScript types generation would go here");
}

// Run if called directly
if (require.main === module) {
  generateApiDocs();
}
```

### **Package.json Scripts**

```json
{
  "scripts": {
    "docs:generate": "tsx scripts/generate-api-docs.ts",
    "docs:serve": "next dev --port 3001",
    "docs:build": "npm run docs:generate && next build",
    "docs:validate": "swagger-codegen validate public/api-spec.json"
  }
}
```

## **API Documentation Best Practices**

### **Conventions**

1. **Consistent Naming**: Use kebab-case for URLs, camelCase for JSON
2. **Descriptive Examples**: Real-world data examples
3. **Error Examples**: Include common error scenarios
4. **Version Headers**: Always specify API version
5. **Request IDs**: Include request tracking
6. **Rate Limiting**: Document limits and headers

### **Quality Checklist**

- [ ] All endpoints documented with JSDoc
- [ ] Request/response examples provided
- [ ] Error cases documented
- [ ] Schema validation in place
- [ ] Contract tests passing
- [ ] Types generated from spec
- [ ] Swagger UI accessible
- [ ] API versioning documented

### **Maintenance**

- **Automated Generation**: CI/CD updates docs on API changes
- **Breaking Changes**: Version bumps and deprecation notices
- **Backward Compatibility**: Maintain old versions until sunset
- **Testing**: Documentation accuracy validated by tests

## **External API Documentation**

### **Public API Portal**

```typescript
// app/docs/page.tsx - Public API documentation portal
import { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Avocado HP API Documentation',
  description: 'Complete API reference for the Farm Management System'
}

export default function ApiDocsPortal() {
  return (
    <div className="min-h-screen bg-background">
      <header className="border-b">
        <div className="container mx-auto px-4 py-6">
          <h1 className="text-3xl font-bold">Avocado HP API</h1>
          <p className="text-muted-foreground mt-2">
            Farm Management System API Documentation
          </p>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Quick Start */}
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Quick Start</h2>
            <div className="space-y-2">
              <a href="/api-docs" className="block p-4 border rounded-lg hover:bg-accent">
                📚 Interactive API Explorer
              </a>
              <a href="/public/api-spec.json" className="block p-4 border rounded-lg hover:bg-accent">
                📄 OpenAPI Specification
              </a>
              <a href="/docs/authentication" className="block p-4 border rounded-lg hover:bg-accent">
                🔐 Authentication Guide
              </a>
            </div>
          </div>

          {/* Resources */}
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">API Resources</h2>
            <div className="space-y-2">
              <a href="/docs/machineries" className="block p-4 border rounded-lg hover:bg-accent">
                🚜 Machineries API
              </a>
              <a href="/docs/employees" className="block p-4 border rounded-lg hover:bg-accent">
                👥 Employees API
              </a>
              <a href="/docs/suppliers" className="block p-4 border rounded-lg hover:bg-accent">
                🏪 Suppliers API
              </a>
            </div>
          </div>

          {/* Developer Tools */}
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Developer Tools</h2>
            <div className="space-y-2">
              <a href="/docs/sdks" className="block p-4 border rounded-lg hover:bg-accent">
                📦 SDKs & Libraries
              </a>
              <a href="/docs/postman" className="block p-4 border rounded-lg hover:bg-accent">
                📮 Postman Collection
              </a>
              <a href="/docs/changelog" className="block p-4 border rounded-lg hover:bg-accent">
                📋 API Changelog
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
```

## **Integration Examples**

### **cURL Examples**

```bash
# List machineries with pagination
curl -X GET "https://api.avocado-hp.com/api/v1/properties/machineries?page=1&limit=10" \
  -H "Cookie: better-auth.session_token=your-session-token" \
  -H "Content-Type: application/json"

# Create new machinery
curl -X POST "https://api.avocado-hp.com/api/v1/properties/machineries" \
  -H "Cookie: better-auth.session_token=your-session-token" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Deere 6130",
    "type": "TRACTOR",
    "hourlyRate": 175.50,
    "description": "Heavy-duty tractor for field work"
  }'

# Update machinery
curl -X PUT "https://api.avocado-hp.com/api/v1/properties/machineries/cm123abc" \
  -H "Cookie: better-auth.session_token=your-session-token" \
  -H "Content-Type: application/json" \
  -d '{
    "hourlyRate": 180.00,
    "status": "MAINTENANCE"
  }'
```

### **JavaScript/TypeScript SDK**

```typescript
// lib/sdk/avocado-hp-client.ts
export class AvocadoHPClient {
  private baseUrl: string;
  private sessionToken?: string;

  constructor(baseUrl: string, sessionToken?: string) {
    this.baseUrl = baseUrl;
    this.sessionToken = sessionToken;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {},
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        "Content-Type": "application/json",
        ...(this.sessionToken && {
          Cookie: `better-auth.session_token=${this.sessionToken}`,
        }),
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`API Error: ${error.error.message}`);
    }

    return response.json();
  }

  // Machineries
  async getMachineries(params?: {
    page?: number;
    limit?: number;
    search?: string;
    type?: string;
    status?: string;
  }) {
    const query = new URLSearchParams(params as any).toString();
    return this.request<PaginatedApiResponse<Machinery>>(
      `/api/v1/properties/machineries${query ? `?${query}` : ""}`,
    );
  }

  async createMachinery(data: CreateMachineryRequest) {
    return this.request<ApiResponse<Machinery>>(
      "/api/v1/properties/machineries",
      {
        method: "POST",
        body: JSON.stringify(data),
      },
    );
  }

  async updateMachinery(id: string, data: UpdateMachineryRequest) {
    return this.request<ApiResponse<Machinery>>(
      `/api/v1/properties/machineries/${id}`,
      {
        method: "PUT",
        body: JSON.stringify(data),
      },
    );
  }
}
```
