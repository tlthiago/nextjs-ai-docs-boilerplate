# Component Patterns - Avocado HP

> **📚 Documentação Fragmentada**: Esta é uma versão resumida. Para detalhes completos, consulte a [documentação modular em `/docs/components/`](./components/).

## 🧩 Component Architecture Overview

### Quick Reference Structure

```
src/app/(private)/[resource]/
├── page.tsx                    # Lista (queries apenas)
├── adicionar/page.tsx         # Criação (mutations)
├── editar/[id]/page.tsx      # Edição (queries + mutations)
└── _components/              # Componentes específicos
    ├── [resource]-data-table.tsx          # DataTable puro
    ├── [resource]-columns.tsx             # Definições de colunas
    ├── [resource]-data-table-row-actions.tsx  # RowActions (mutations)
    └── [resource]-form.tsx                # Formulário
```

## 📋 Component Responsibilities

| Component         | Queries        | Mutations        | Rendering              | Navigation  |
| ----------------- | -------------- | ---------------- | ---------------------- | ----------- |
| **Page (List)**   | ✅ `useQuery`  | ❌               | Layout                 | Links       |
| **Page (Create)** | Dependencies   | ✅ `useMutation` | Form integration       | ✅ Redirect |
| **Page (Edit)**   | ✅ Item + deps | ✅ `useMutation` | Form integration       | ✅ Redirect |
| **DataTable**     | ❌ Props only  | ❌               | ✅ Pure render         | ❌          |
| **RowActions**    | ❌             | ✅ Line actions  | Dropdown               | Edit links  |
| **Form**          | ❌             | ❌ Callback      | ✅ Fields + validation | ❌          |

## 🔄 TanStack Query Pattern Summary

### Query Placement

```typescript
// ✅ Pages - Data fetching
const { data: employees } = useQuery({
  queryKey: ["employees"],
  queryFn: getEmployees,
});

// ✅ RowActions - Line mutations
const { mutate: deleteEmployee } = useMutation({
  mutationFn: deleteEmployeeService,
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ["employees"] }),
});
```

### Key Patterns

```typescript
// Simple keys
["employees"][("employees", id)]["categories"][ // List // Item // Dependencies
  // Filtered keys
  ("employees", { status: "ACTIVE" })
][("suppliers", { categoryId: "123" })];
```

## 📊 Example Implementation

### List Page Pattern

```typescript
// funcionarios/page.tsx
export default function EmployeesPage() {
  const { data: employees, isLoading } = useQuery({
    queryKey: ["employees"],
    queryFn: getEmployees,
  });

  return (
    <div className="space-y-6">
      <PageHeader title="Funcionários" />
      {employees && <EmployeesDataTable employees={employees} isLoading={isLoading} />}
    </div>
  );
}
```

### DataTable Pattern

```typescript
// _components/employees-data-table.tsx
export function EmployeesDataTable({ employees, isLoading }: Props) {
  const columns = createEmployeeColumns();

  if (isLoading) return <TableSkeleton />;

  return <DataTable columns={columns} data={employees} />;
}
```

### RowActions Pattern

```typescript
// _components/employees-data-table-row-actions.tsx
export function EmployeesDataTableRowActions({ row }: Props) {
  const employee = row.original as Employee;
  const queryClient = useQueryClient();

  const { mutateAsync: deleteEmployee } = useMutation({
    mutationFn: deleteEmployeeService,
    onSuccess: () => {
      toast.success("Funcionário excluído!");
      queryClient.invalidateQueries({ queryKey: ["employees"] });
    },
  });

  return (
    <DropdownMenu>
      <DropdownMenuContent>
        <Link href={`funcionarios/editar/${employee.id}`}>
          <DropdownMenuItem>Editar</DropdownMenuItem>
        </Link>
        <DropdownMenuItem onClick={() => deleteEmployee(employee.id)}>
          Excluir
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
```

## 📖 Detailed Documentation

Para implementações completas e padrões avançados, consulte:

- **[📁 Folder Structure](./components/folder-structure.md)** - Organização de arquivos e nomenclatura
- **[🎯 Component Responsibilities](./components/component-responsibilities.md)** - Separação de responsabilidades
- **[📄 Page Patterns](./components/page-patterns.md)** - Padrões de páginas (lista, criar, editar)
- **[📝 Form Patterns](./components/form-patterns.md)** - React Hook Form + Zod patterns
- **[🗃️ DataTable Patterns](./components/datatable-patterns.md)** - DataTable, colunas e RowActions
- **[🔄 TanStack Query Patterns](./components/tanstack-query-patterns.md)** - Estado assíncrono e cache

## 🎯 Quick Guidelines

### ✅ Do's

- Queries apenas em pages
- Mutations onde são usadas (RowActions, Create/Edit pages)
- DataTables como componentes puros
- Cache invalidation após mutations
- Loading states e error handling

### ❌ Don'ts

- Queries em DataTables
- Mutations em componentes de rendering
- Navegação sem feedback
- Ignorar estados de erro
- Cache desatualizado após operações
