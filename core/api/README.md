# API Patterns - Modular Documentation

> **📚 This is the detailed documentation for universal API patterns**. For a quick overview, check the [main file](../05-API-PATTERNS.md).

## � Estrutura da Documentação

Esta documentação está organizada de forma modular para facilitar a navegação e manutenção:

### 🛣️ **Estrutura e Rotas**

- **[Route Structure](./route-structure.md)** - Convenções de roteamento e estrutura de URLs
- **[Request & Response](./request-response.md)** - Padrões de entrada e saída da API

### 🔐 **Segurança e Validação**

- **[Authentication](./authentication.md)** 🔄 - Implementação de autenticação e autorização
- **[Validation](./validation.md)** 🔄 - Validação de dados com Zod
- **[Error Handling](./error-handling.md)** 🔄 - Tratamento padronizado de erros

### 🎯 **Operações e Performance**

- **[CRUD Operations](./crud-operations.md)** 🔄 - Implementações completas de CRUD
- **[Middleware](./middleware.md)** 🔄 - Middlewares customizados e interceptadores
- **[Performance](./performance.md)** 🔄 - Otimizações e boas práticas de performance

## � Quick Start

Para implementar uma nova API, siga esta sequência:

1. **Definir estrutura** → [Route Structure](./route-structure.md)
2. **Implementar CRUD** → [CRUD Operations](./crud-operations.md)
3. **Adicionar validação** → [Validation](./validation.md)
4. **Configurar autenticação** → [Authentication](./authentication.md)
5. **Tratar erros** → [Error Handling](./error-handling.md)

## 📋 Templates Prontos

### Estrutura Básica de Rota

```typescript
// /api/v1/entities/route.ts
import { getAuthenticatedSession } from "@/lib/api/api-guard";

export async function GET() {
  const session = await getAuthenticatedSession();
  // Implementação...
}
```

### Validação com Zod

```typescript
import { entitySchema } from "@/services/entities/schemas";

export async function POST(request: NextRequest) {
  const body = await request.json();
  const data = entitySchema.parse(body); // Validação automática
  // Implementação...
}
```

### Response Padrão

```typescript
return NextResponse.json({
  data: result,
  message: "Operação realizada com sucesso",
});
```

## 🔧 Convenções Importantes

### ✅ Sempre Faça

- Use autenticação em todas as rotas
- Valide entrada com Zod schemas
- Implemente soft delete
- Inclua audit fields
- Retorne responses padronizadas

### ❌ Nunca Faça

- Rotas sem autenticação
- Deletar fisicamente registros
- Ignorar validação
- Retornar dados sensíveis
- Usar status codes incorretos

## 🎯 Padrões de Status

| Status | Uso                          | Exemplo             |
| ------ | ---------------------------- | ------------------- |
| 200    | Sucesso (GET, PATCH, DELETE) | Dados retornados    |
| 201    | Criação (POST)               | Recurso criado      |
| 400    | Bad Request                  | JSON malformado     |
| 401    | Unauthorized                 | Não autenticado     |
| 404    | Not Found                    | Recurso inexistente |
| 422    | Validation Error             | Dados inválidos     |
| 500    | Server Error                 | Erro interno        |

## 📖 Navegação Rápida

- **[← Voltar ao índice principal](../README.md)**
- **[📊 Data Patterns →](../data/README.md)**
- **[🧩 Component Patterns →](../components/README.md)**

---

**💡 Dica**: Use Ctrl+F para buscar rapidamente por padrões específicos dentro de cada documento modular.
