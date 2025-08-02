# Folder Structure & Naming Conventions

## 🗂️ Component Structure

### Global Components

```
src/components/
├── ui/                      # Radix UI primitives (shadcn/ui)
│   ├── button.tsx
│   ├── dialog.tsx
│   ├── form.tsx
│   ├── input.tsx
│   ├── table.tsx
│   └── ...
├── data-table/              # Reusable data table components
│   ├── data-table.tsx
│   ├── data-table-toolbar.tsx
│   ├── data-table-pagination.tsx
│   └── data-table-column-header.tsx
├── navbar.tsx               # App navigation
├── sidebar.tsx              # App sidebar
└── forms/                   # Domain-specific shared forms
    ├── machinery-form.tsx
    ├── supplier-form.tsx
    └── employee-form.tsx
```

### Page-Specific Components

```
src/app/(private)/[resource]/
├── page.tsx                           # Lista principal
├── adicionar/
│   └── page.tsx                       # Página de criação
├── editar/
│   └── [id]/
│       └── page.tsx                   # Página de edição
└── _components/                       # Componentes específicos do recurso
    ├── [resource]-data-table.tsx      # DataTable component
    ├── [resource]-columns.tsx         # Column definitions
    ├── [resource]-data-table-row-actions.tsx  # Row actions
    ├── [resource]-stats-cards.tsx     # Statistics cards
    └── [resource]-form.tsx            # Resource-specific form
```

## 📝 Naming Conventions

### Files & Folders

- **Files**: `kebab-case.tsx` (ex: `employee-data-table.tsx`)
- **Folders**: `kebab-case` (ex: `_components`, `data-table`)
- **Page files**: Sempre `page.tsx`

### Components

- **Component Names**: `PascalCase` (ex: `EmployeeDataTable`)
- **Props**: `camelCase` (ex: `isLoading`, `onSubmit`)
- **Interfaces**: `PascalCase` + suffix (ex: `EmployeeFormProps`)

### Variables & Functions

- **Variables**: `camelCase` (ex: `isLoading`, `employees`)
- **Functions**: `camelCase` (ex: `handleSubmit`, `createEmployee`)
- **Constants**: `UPPER_SNAKE_CASE` (ex: `API_BASE_URL`)

## 🎯 Component Patterns

### Resource-Specific Components

```typescript
// Exemplo para "employees"
export function EmployeesDataTable() {} // ✅
export function EmployeeDataTable() {} // ❌ (singular)

// Arquivo: employee-data-table.tsx
// Component: EmployeesDataTable
```

### Generic Components

```typescript
// Componentes reutilizáveis usam singular
export function DataTable() {} // ✅
export function FormField() {} // ✅
export function Badge() {} // ✅
```

## 📁 Import Organization

### Import Order

```typescript
// 1. React & Next.js
import { useState } from "react";
import { useRouter } from "next/navigation";

// 2. External libraries
import { useQuery } from "@tanstack/react-query";
import { zodResolver } from "@hookform/resolvers/zod";

// 3. Internal utilities & services
import { getEmployees } from "@/services/employees";
import { cn } from "@/lib/utils";

// 4. Internal components
import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/data-table/data-table";

// 5. Types & schemas
import { Employee } from "@prisma/client";
import { CreateEmployeeInput } from "@/services/employees/schemas";
```

### Path Aliases

```typescript
// ✅ Use path aliases
import { Button } from "@/components/ui/button";
import { getEmployees } from "@/services/employees";

// ❌ Avoid relative imports
import { Button } from "../../../components/ui/button";
import { getEmployees } from "../../../services/employees";
```

## 🔧 File Organization Best Practices

### Single Responsibility

- **1 componente por arquivo** (exceto pequenos helpers)
- **Nome do arquivo = nome do componente**
- **Exports named** ao invés de default quando possível

### Co-location

- **Componentes específicos** ficam na pasta `_components` do recurso
- **Componentes reutilizáveis** ficam em `src/components/`
- **Types específicos** ficam junto com o componente que os usa

### Example Structure

```
funcionarios/
├── page.tsx                           # Main page
├── adicionar/page.tsx                 # Create page
├── editar/[id]/page.tsx              # Edit page
└── _components/
    ├── employees-data-table.tsx       # Table component
    ├── employees-columns.tsx          # Column definitions
    ├── employees-data-table-row-actions.tsx  # Row actions
    ├── employees-stats-cards.tsx      # Stats component
    └── types.ts                       # Component-specific types
```
