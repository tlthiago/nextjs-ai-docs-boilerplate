# Component Documentation - Avocado HP

Esta pasta contém a documentação detalhada dos padrões de componentes do sistema.

## 📁 Estrutura da Documentação

### Core Patterns

- **[page-patterns.md](./page-patterns.md)** - Padrões de páginas (lista, criar, editar)
- **[form-patterns.md](./form-patterns.md)** - Componentes de formulário com React Hook Form + Zod
- **[datatable-patterns.md](./datatable-patterns.md)** - DataTable, colunas e RowActions
- **[tanstack-query-patterns.md](./tanstack-query-patterns.md)** - TanStack Query integration patterns

### Architecture

- **[folder-structure.md](./folder-structure.md)** - Estrutura de pastas e convenções de nomenclatura
- **[component-responsibilities.md](./component-responsibilities.md)** - Separação de responsabilidades entre componentes

### Advanced Patterns (Em Progresso)

- **ui-components.md** 🔄 - Componentes base do design system (Button, Input, Card, etc.)
- **layout-patterns.md** 🔄 - Padrões de layout e estruturação de páginas
- **state-management.md** 🔄 - Gerenciamento de estado local e global
- **error-boundaries.md** 🔄 - Tratamento de erros em componentes
- **performance-patterns.md** 🔄 - Otimizações de performance (memo, lazy loading)
- **accessibility-patterns.md** 🔄 - Padrões de acessibilidade e ARIA
- **testing-patterns.md** 🔄 - Estratégias de teste para componentes

## 🧩 Quick Reference

### Page Types

```
📁 /[resource]/
├── page.tsx (Lista - apenas queries)
├── adicionar/page.tsx (Create - mutations)
├── editar/[id]/page.tsx (Edit - queries + mutations)
└── _components/ (Componentes específicos)
```

### Component Responsibilities

- **Page**: Queries, cache management, navigation
- **DataTable**: Pure rendering, no state
- **RowActions**: Line-specific mutations
- **Forms**: Form state, validation, submission

### TanStack Query Flow

```
Page → useQuery/useMutation → Service → API Route → Database
```

## 📖 Como Usar

1. **Para implementar uma nova feature**: Comece com `page-patterns.md`
2. **Para criar formulários**: Consulte `form-patterns.md`
3. **Para tabelas de dados**: Use `datatable-patterns.md`
4. **Para gerenciar estado**: Veja `tanstack-query-patterns.md`

## 🔗 Links Relacionados

- [05-SERVICE-PATTERNS.md](../05-SERVICE-PATTERNS.md) - Camada de serviços HTTP
- [06-API-PATTERNS.md](../06-API-PATTERNS.md) - Padrões de API Routes
- [07-DATA-PATTERNS.md](../07-DATA-PATTERNS.md) - Padrões de banco de dados
