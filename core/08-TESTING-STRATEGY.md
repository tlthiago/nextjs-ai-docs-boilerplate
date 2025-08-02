# Testing Strategy - Avocado HP

> **📚 Para entender as justificativas desta abordagem, consulte**: [Testing Approach - Integration Tests Only](./patterns/testing-approach.md)

## 🎯 **Abordagem: Integration Tests Only**

Implementamos **testes de integração exclusivamente** usando **Jest + Testcontainers**. Esta estratégia testa o fluxo completo: HTTP → API → Database → Response.

---

## 🏗️ **Stack Técnica Obrigatória**

### **Tecnologias para Usar**

- 🧪 **Jest v30** - Test runner, assertions, coverage
- 🐳 **Testcontainers** - PostgreSQL 15 real em containers Docker
- 🌐 **Fetch API nativo** - Requisições HTTP reais (nunca supertest)
- 🔐 **Better Auth** - Cookies reais de autenticação
- 📊 **Jest Coverage** - Relatórios automáticos

### **Configuração Jest Obrigatória**

```typescript
// jest.integration.config.ts
const config: Config = {
  displayName: "Integration Tests",
  testEnvironment: "node",
  testMatch: ["**/__tests__/**/*.test.ts"],
  globalSetup: "<rootDir>/__tests__/helpers/jest-global-setup.ts",
  globalTeardown: "<rootDir>/__tests__/helpers/jest-global-teardown.ts",
  maxWorkers: 1, // Serial execution obrigatória
  testTimeout: 60000, // Para startup de containers
};
```

---

## 📂 **Estrutura de Arquivos Obrigatória**

```
__tests__/
├── api/                                # Integration Tests APENAS
│   └── properties/
│       ├── machineries/                # ✅ Implementado
│       │   ├── get-machineries.test.ts
│       │   ├── post-machineries.test.ts
│       │   └── patch-machineries.test.ts
│       ├── employees/                  # 🔄 Próximo
│       │   └── [crud-tests].test.ts
│       └── suppliers/                  # 🔄 Próximo
│           └── [crud-tests].test.ts
├── helpers/                            # Test Utilities
│   ├── auth.ts                        # authenticateUser()
│   ├── testcontainers.ts              # setupTestDatabase()
│   ├── test-setup.ts                  # setupTestEnvironment()
│   ├── jest-global-setup.ts           # Global setup
│   ├── jest-global-teardown.ts        # Global teardown
│   └── factories/                     # Test data generators
│       ├── machinery.ts               # createMachineryData()
│       ├── user.ts                    # createUserData()
│       └── supplier.ts                # createSupplierData()
```

---

## 📋 **Template Obrigatório para Agentes**

### **Estrutura Padrão de Teste**

```typescript
import { beforeAll, describe, expect, it } from "@jest/globals";
import { authenticateUser } from "../../../helpers/auth";
import { createResourceData } from "../../../helpers/factories/[resource]";

describe("/api/properties/[resource]", () => {
  const baseUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";
  let authCookie: string;
  let createdResourceId: string; // Se precisar de dados existentes

  beforeAll(async () => {
    // 1. SEMPRE autenticar primeiro
    authCookie = await authenticateUser();

    // 2. Criar dados de teste se necessário (para GET/PATCH/DELETE)
    if (needsTestData) {
      const testData = createResourceData();
      const response = await fetch(`${baseUrl}/api/v1/properties/[resource]`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Cookie: authCookie,
        },
        body: JSON.stringify(testData),
      });
      const data = await response.json();
      createdResourceId = data.id;
    }
  });

  describe("METHOD /api/v1/properties/[resource]", () => {
    describe("success cases", () => {
      it("should [action] with valid data", async () => {
        // 1. Fazer requisição HTTP real com fetch()
        const response = await fetch(
          `${baseUrl}/api/v1/properties/[resource]`,
          {
            method: "METHOD",
            headers: {
              "Content-Type": "application/json",
              Cookie: authCookie, // SEMPRE incluir auth
            },
            body: JSON.stringify(validData),
          },
        );

        // 2. Validar status HTTP específico
        expect(response.status).toBe(200); // ou 201

        // 3. Validar estrutura completa da resposta
        const data = await response.json();
        expect(data).toHaveProperty("id");
        expect(data.name).toBe(expectedName);
        expect(typeof data.id).toBe("string");
        expect(typeof data.name).toBe("string");
      });
    });

    describe("error cases", () => {
      it("should return 401 when not authenticated", async () => {
        // Requisição sem Cookie
        const response = await fetch(`${baseUrl}/api/v1/properties/[resource]`);

        expect(response.status).toBe(401);
        const error = await response.json();
        expect(error).toEqual({
          message: "Não autorizado.", // Mensagem EXATA
          code: "UNAUTHORIZED", // Código EXATO
        });
      });

      it("should return 400 when data is invalid", async () => {
        const response = await fetch(
          `${baseUrl}/api/v1/properties/[resource]`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Cookie: authCookie,
            },
            body: JSON.stringify(invalidData),
          },
        );

        expect(response.status).toBe(400);
        const error = await response.json();
        expect(error).toHaveProperty("code", "VALIDATION_ERROR");
      });
    });
  });
});
```

---

## 🐳 **Setup Testcontainers (Implementado)**

### **Container PostgreSQL**

```typescript
// __tests__/helpers/testcontainers.ts
export async function setupTestDatabase(): Promise<string> {
  container = await new PostgreSqlContainer("postgres:15")
    .withDatabase("test_db")
    .withUsername("test_user")
    .withPassword("test_password")
    .withExposedPorts(5432)
    .start();

  process.env.DATABASE_URL = container.getConnectionUri();
  return container.getConnectionUri();
}
```

### **Environment Setup**

```typescript
// __tests__/helpers/test-setup.ts
export async function setupTestEnvironment(): Promise<void> {
  const databaseUrl = await setupTestDatabase();

  // Reset database + migrações
  execSync("npx prisma migrate reset --force", {
    env: { ...process.env, DATABASE_URL: databaseUrl },
  });

  // Gerar Prisma client
  execSync("npx prisma generate");
}
```

---

## 🎯 **Regras Obrigatórias para Agentes**

### **✅ SEMPRE FAZER**

1. **Usar template exato** - Copie a estrutura obrigatória acima
2. **Fetch API nativo** - `fetch()`, nunca supertest ou axios
3. **Autenticação real** - `authCookie = await authenticateUser()`
4. **Validações específicas** - Mensagens exatas, não `expect.any()`
5. **Estrutura de describes** - `/api/properties/[resource]` → `METHOD` → `success/error cases`
6. **Testcontainers** - PostgreSQL real, nunca mocks
7. **Execução serial** - `maxWorkers: 1` no Jest config
8. **Factory data** - `createResourceData()` para dados consistentes
9. **Error cases obrigatórios** - 401, 400, 404 com mensagens exatas
10. **Headers corretos** - `Content-Type: application/json` + `Cookie: authCookie`

### **❌ NUNCA FAZER**

1. **Não usar supertest** - Fetch nativo obrigatório
2. **Não mockar HTTP** - Requisições reais obrigatórias
3. **Não mockar database** - Testcontainers obrigatório
4. **Não usar expect.any() em errors** - Mensagens específicas
5. **Não skip testes** - Todos devem passar sempre
6. **Não usar console.log** - Jest já mostra output
7. **Não hardcode URLs** - `process.env.NEXT_PUBLIC_API_URL`
8. **Não esquecer autenticação** - Cookie em todas as requests
9. **Não criar unit tests** - Apenas integration tests
10. **Não usar jsdom** - `testEnvironment: "node"` apenas

### **Cenários Obrigatórios de Teste**

#### **Success Cases**

- ✅ Happy path com dados válidos
- ✅ Estrutura completa da resposta
- ✅ Tipos corretos dos campos
- ✅ Relacionamentos incluídos

#### **Error Cases**

- ✅ `401` - Não autenticado (sem Cookie)
- ✅ `400` - Dados inválidos (Zod validation)
- ✅ `404` - Recurso não encontrado
- ✅ Business logic errors específicos

---


## 🧮 **Integration Tests = Business Logic Tests**

### **Exemplo Prático: API de Pedidos com Cálculos**

Este exemplo mostra como integration tests testam TODA a lógica de negócio:

```typescript
// src/app/api/orders/route.ts
export async function POST(request: Request) {
  const data = await request.json();
  
  // 🔢 LÓGICA DE NEGÓCIO AQUI:
  const subtotal = calculateSubtotal(data.items);
  const discount = calculateDiscount(subtotal, data.discountCode);
  const tax = calculateTax(subtotal - discount, data.customerState);
  const total = subtotal - discount + tax;
  
  // 🗄️ VALIDAÇÃO DE NEGÓCIO:
  if (total > data.customer.creditLimit) {
    return Response.json(
      { message: "Credit limit exceeded", code: "CREDIT_LIMIT" },
      { status: 400 }
    );
  }
  
  // 💾 PERSISTÊNCIA:
  const order = await prisma.order.create({
    data: { ...data, subtotal, discount, tax, total }
  });
  
  return Response.json(order, { status: 201 });
}

// 🧮 FUNÇÕES DE CÁLCULO:
function calculateSubtotal(items: Item[]) {
  return items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
}

function calculateDiscount(subtotal: number, code?: string) {
  if (code === 'SAVE20') return subtotal * 0.2;
  if (code === 'FIRST10') return Math.min(subtotal * 0.1, 50);
  return 0;
}

function calculateTax(amount: number, state: string) {
  const taxRates = { SP: 0.18, RJ: 0.19, MG: 0.17 };
  return amount * (taxRates[state] || 0.15);
}
```

### **Integration Test que testa TODA a lógica:**

```typescript
describe("POST /api/orders - Business Logic Integration", () => {
  it("should calculate order total with discount and tax correctly", async () => {
    // 🎯 SETUP: Customer com limite de crédito
    const customer = await createTestCustomer({ creditLimit: 1000 });
    
    // 📋 REQUEST: Pedido com desconto
    const orderData = {
      customerId: customer.id,
      customerState: 'SP', // 18% ICMS
      discountCode: 'SAVE20', // 20% desconto
      items: [
        { productId: 1, price: 100, quantity: 2 }, // R$ 200
        { productId: 2, price: 50, quantity: 1 }   // R$ 50
      ]
    };

    // 🚀 CHAMADA API (Point A)
    const response = await fetch(`${baseUrl}/api/orders`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: authCookie,
      },
      body: JSON.stringify(orderData)
    });

    // ✅ VALIDAÇÃO COMPLETA DA LÓGICA:
    expect(response.status).toBe(201);
    const order = await response.json();
    
    // 🧮 TESTANDO TODOS OS CÁLCULOS:
    expect(order.subtotal).toBe(250);  // 100*2 + 50*1
    expect(order.discount).toBe(50);   // 250 * 0.2 (SAVE20)
    expect(order.tax).toBe(36);        // (250-50) * 0.18 (SP)
    expect(order.total).toBe(236);     // 250 - 50 + 36
    
    // 💾 VALIDAÇÃO NO BANCO (Point B):
    const dbOrder = await prisma.order.findUnique({
      where: { id: order.id },
      include: { items: true }
    });
    
    expect(dbOrder).toBeTruthy();
    expect(dbOrder.total).toBe(236);
    expect(dbOrder.items).toHaveLength(2);
  });

  it("should reject order when exceeds credit limit", async () => {
    // 🎯 SETUP: Customer com limite baixo
    const customer = await createTestCustomer({ creditLimit: 100 });
    
    const orderData = {
      customerId: customer.id,
      customerState: 'SP',
      items: [{ productId: 1, price: 200, quantity: 1 }] // R$ 236 total
    };

    // 🚀 CHAMADA API
    const response = await fetch(`${baseUrl}/api/orders`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Cookie: authCookie,
      },
      body: JSON.stringify(orderData)
    });

    // ✅ TESTANDO VALIDAÇÃO DE NEGÓCIO:
    expect(response.status).toBe(400);
    const error = await response.json();
    expect(error).toEqual({
      message: 'Credit limit exceeded',
      code: 'CREDIT_LIMIT'
    });

    // 💾 CONFIRMA QUE NÃO SALVOU NO BANCO:
    const orderCount = await prisma.order.count({
      where: { customerId: customer.id }
    });
    expect(orderCount).toBe(0);
  });
});
```

### **Por que isso responde a questão "Integration Tests testam Business Logic?":**

1. **✅ SIM**, integration tests testam lógica de negócio completa
2. **✅ SIM**, testam cálculos matemáticos (`calculateDiscount`, `calculateTax`)
3. **✅ SIM**, testam validações de negócio (`creditLimit exceeded`)
4. **✅ SIM**, vão do Point A (HTTP request) ao Point B (database) passando por TODA a lógica

### **Nomenclatura correta:**
- **Unit test**: Testaria apenas `calculateDiscount()` isoladamente
- **Integration test**: Testa HTTP → Parsing → Cálculos → Validações → Database → Response
- **E2E test**: Testaria via browser com UI completa

**Nossa abordagem = Integration Tests que cobrem Business Logic completamente.**

### **Vantagens desta abordagem:**
- 🎯 **Confiança real** - Se o teste passa, o feature funciona end-to-end
- 🐛 **Bugs são raros** - Testamos o fluxo que o usuário realmente usa
- 🧮 **Business logic incluída** - Cálculos, validações, tudo testado junto
- 🔄 **Refactor seguro** - Pode mudar implementação interna sem quebrar testes
- 🤖 **AI-friendly** - Agentes entendem o comportamento completo da API

---
## 🔧 **Comandos de Execução**

```bash
# Executar testes de integração
npm run test:integration

# Executar com coverage
npm run test:coverage

# Watch mode para desenvolvimento
npm run test:watch

# Testes específicos
npm run test -- __tests__/api/properties/[resource]

# Debug detalhado
npm run test -- --verbose --detectOpenHandles
```

---

## 📊 **Status Atual de Implementação**

### **✅ Implementado**

- **Machineries CRUD** - GET, POST, PATCH (3 arquivos)
- **Authentication helpers** - `authenticateUser()`
- **Testcontainers setup** - PostgreSQL 15 funcionando
- **CI/CD pipeline** - GitHub Actions configurado
- **Factory patterns** - `createMachineryData()`

### **🔄 Próximos a Implementar**

- **Employees CRUD** - Todos os endpoints
- **Suppliers CRUD** - Todos os endpoints
- **More edge cases** - Cenários específicos de negócio

### **📈 Métricas**

- **Cobertura**: Machineries 100%
- **Tempo execução**: ~3 minutos local, ~8 minutos CI
- **Success rate**: 100% dos testes passando

---

## 🤖 **Exemplo Prático para Agentes**

### **Para criar testes de Employees:**

```typescript
describe("/api/properties/employees", () => {
  const baseUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";
  let authCookie: string;

  beforeAll(async () => {
    authCookie = await authenticateUser();
  });

  describe("POST /api/v1/properties/employees", () => {
    describe("success cases", () => {
      it("should create employee with valid data", async () => {
        const newEmployee = {
          name: "João Silva",
          email: "joao@example.com",
          position: "OPERATOR",
        };

        const response = await fetch(`${baseUrl}/api/v1/properties/employees`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Cookie: authCookie,
          },
          body: JSON.stringify(newEmployee),
        });

        expect(response.status).toBe(201);
        const data = await response.json();
        expect(data).toHaveProperty("id");
        expect(data.name).toBe("João Silva");
        expect(data.email).toBe("joao@example.com");
        expect(data.position).toBe("OPERATOR");
      });
    });

    describe("error cases", () => {
      it("should return 401 when not authenticated", async () => {
        const response = await fetch(`${baseUrl}/api/v1/properties/employees`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({}),
        });

        expect(response.status).toBe(401);
        const error = await response.json();
        expect(error).toEqual({
          message: "Não autorizado.",
          code: "UNAUTHORIZED",
        });
      });
    });
  });
});
```

---

## 🛠️ **Dependencies Obrigatórias**

```json
{
  "devDependencies": {
    "jest": "^30.0.5",
    "@jest/globals": "^30.0.0",
    "@types/jest": "^30.0.0",
    "@testcontainers/postgresql": "^10.13.2",
    "ts-jest": "^29.4.0"
  },
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:integration": "jest --config jest.integration.config.ts --runInBand"
  }
}
```

---

**Status**: ✅ **Implementado e Funcionando**  
**Cobertura**: Machineries 100%, Employees/Suppliers em desenvolvimento  
**Pipeline**: ✅ CI/CD funcionando  
**Próximo**: Implementar testes para Employees e Suppliers
