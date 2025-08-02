# Data Patterns - Modular Documentation

> **📚 This is the detailed documentation for universal data patterns**. For a quick overview, check the [main file](../03-DATA-PATTERNS.md).

## � Estrutura da Documentação

Esta documentação está organizada de forma modular para facilitar a navegação e manutenção:

### 🏗️ **Schema e Estrutura**

- **[Schema Design](./schema-design.md)** - Convenções de design de schema e entidades
- **[Relationships](./relationships.md)** 🔄 - Modelagem de relacionamentos entre entidades
- **[Audit Fields](./audit-fields.md)** 🔄 - Sistema automático de auditoria

### 🔍 **Queries e Validação**

- **[Query Patterns](./query-patterns.md)** - Padrões otimizados de consulta
- **[Validation Schemas](./validation-schemas.md)** 🔄 - Schemas Zod para validação
- **[Performance](./performance.md)** 🔄 - Otimizações de query e índices

### 🔄 **Transações e Migrações**

- **[Transactions](./transactions.md)** 🔄 - Gestão de transações e consistência
- **[Migrations](./migrations.md)** 🔄 - Estratégias de migração e versionamento

## 🚀 Quick Start

Para criar uma nova entidade, siga esta sequência:

1. **Definir schema** → [Schema Design](./schema-design.md)
2. **Configurar relacionamentos** → [Relationships](./relationships.md)
3. **Criar schemas de validação** → [Validation Schemas](./validation-schemas.md)
4. **Implementar queries** → [Query Patterns](./query-patterns.md)
5. **Criar migração** → [Migrations](./migrations.md)

## � Templates Prontos

### Entidade Base

```prisma
model EntityName {
  id          String   @id @default(cuid())
  name        String
  status      Status   @default(ACTIVE)

  // Audit fields
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  createdById String
  updatedById String?

  // Relations
  createdBy   User     @relation("EntityCreatedBy", fields: [createdById], references: [id])
  updatedBy   User?    @relation("EntityUpdatedBy", fields: [updatedById], references: [id])

  @@map("entity_names")
}
```

### Schema Zod

```typescript
export const entitySchema = z.object({
  name: z.string().min(1, "Nome é obrigatório"),
  status: z.enum(["ACTIVE", "INACTIVE"]).default("ACTIVE"),
});

export type EntityInput = z.infer<typeof entitySchema>;
```

### Query Padrão

```typescript
const entities = await prisma.entity.findMany({
  where: { status: { not: "DELETED" } },
  include: { createdBy: { select: { name: true } } },
  orderBy: { createdAt: "desc" },
});
```

## 🔧 Convenções Importantes

### ✅ Sempre Faça

- Inclua audit fields em todas as entidades
- Use soft delete (status)
- Valide com Zod schemas
- Implemente relacionamentos corretos
- Use transações para operações críticas

### ❌ Nunca Faça

- Deletar fisicamente entidades principais
- Criar entidades sem audit fields
- Ignorar relacionamentos necessários
- Fazer queries sem filtros de status
- Esquecer de incluir dados relacionados

## 🎯 Status Enum Padrão

```prisma
enum Status {
  ACTIVE      // Ativo e visível
  INACTIVE    // Inativo mas visível
  DELETED     // Soft delete - oculto
}
```

## 📊 Audit Fields Automáticos

Todas as entidades incluem:

| Campo       | Tipo     | Descrição                        |
| ----------- | -------- | -------------------------------- |
| createdAt   | DateTime | Data de criação                  |
| updatedAt   | DateTime | Última atualização               |
| createdById | String   | ID do usuário criador            |
| updatedById | String?  | ID do último usuário a atualizar |
| status      | Status   | Status da entidade               |

## 🔗 Tipos de Relacionamento

### One-to-Many

```prisma
// Um usuário cria muitas entidades
createdBy User @relation("EntityCreatedBy", fields: [createdById], references: [id])
```

### Many-to-Many

```prisma
// Através de tabela junction
categories ResourceCategory[]
```

### Self-Referencing

```prisma
// Categoria pai/filhos
parentId    String?
parent      Category? @relation("CategoryParent", fields: [parentId], references: [id])
children    Category[] @relation("CategoryParent")
```

## � Navegação Rápida

- **[← Voltar ao índice principal](../README.md)**
- **[🛣️ API Patterns →](../api/README.md)**
- **[🧩 Component Patterns →](../components/README.md)**

---

**💡 Dica**: Use Ctrl+F para buscar rapidamente por padrões específicos dentro de cada documento modular.
