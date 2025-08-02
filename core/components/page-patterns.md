# Page Patterns

## 📄 Page Structure Overview

### Resource Management Pattern

```
src/app/(private)/[resource]/
├── page.tsx                    # Lista principal
├── adicionar/page.tsx         # Criação
├── editar/[id]/page.tsx      # Edição
└── _components/              # Componentes específicos
```

## 📋 List Page Pattern

### Basic Structure

```typescript
// app/(private)/funcionarios/page.tsx
import { useQuery } from '@tanstack/react-query';
import { getEmployees } from '@/services/employees';
import { EmployeesDataTable } from './_components/employees-data-table';
import { EmployeeStatsCards } from './_components/employee-stats-cards';

export default function EmployeesPage() {
  // ✅ Apenas queries para buscar dados
  const {
    data: employees,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["employees"],
    queryFn: getEmployees,
  });

  // ✅ Error handling
  if (error) {
    return <ErrorMessage error={error} />;
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Funcionários</h1>
          <p className="text-muted-foreground">
            Gerencie funcionários e suas funções
          </p>
        </div>
        <Button asChild>
          <Link href="/funcionarios/adicionar">
            <Plus className="mr-2 h-4 w-4" />
            Adicionar Funcionário
          </Link>
        </Button>
      </div>

      {/* Stats */}
      {employees && <EmployeeStatsCards employees={employees} />}

      {/* Data Table */}
      {employees && (
        <Card>
          <CardContent>
            <EmployeesDataTable
              employees={employees}
              isLoading={isLoading}
            />
          </CardContent>
        </Card>
      )}
    </div>
  );
}
```

### Page Header Pattern

```typescript
interface PageHeaderProps {
  title: string;
  description?: string;
  action?: React.ReactNode;
}

export function PageHeader({ title, description, action }: PageHeaderProps) {
  return (
    <div className="flex items-center justify-between">
      <div>
        <h1 className="text-3xl font-bold">{title}</h1>
        {description && (
          <p className="text-muted-foreground">{description}</p>
        )}
      </div>
      {action}
    </div>
  );
}

// Usage
<PageHeader
  title="Funcionários"
  description="Gerencie funcionários e suas funções"
  action={
    <Button asChild>
      <Link href="/funcionarios/adicionar">
        <Plus className="mr-2 h-4 w-4" />
        Adicionar
      </Link>
    </Button>
  }
/>
```

## ➕ Create Page Pattern

### Basic Structure

```typescript
// app/(private)/funcionarios/adicionar/page.tsx
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import { createEmployee } from '@/services/employees';
import { getCategories } from '@/services/categories';
import { EmployeeForm } from '../_components/employee-form';

export default function CreateEmployeePage() {
  const router = useRouter();
  const queryClient = useQueryClient();

  // ✅ Mutation para criação
  const { mutate: createEmployeeFn, isPending } = useMutation({
    mutationFn: createEmployee,
    onSuccess: () => {
      // Cache invalidation
      queryClient.invalidateQueries({ queryKey: ["employees"] });

      // User feedback
      toast.success("Funcionário criado com sucesso!");

      // Navigation
      router.push("/funcionarios");
    },
    onError: (error: Error) => {
      toast.error("Erro ao criar funcionário", {
        description: error.message,
      });
    },
  });

  // ✅ Queries para recursos dependentes
  const { data: categories = [] } = useQuery({
    queryKey: ["categories"],
    queryFn: getCategories,
  });

  return (
    <div className="space-y-6">
      <PageHeader
        title="Adicionar Funcionário"
        description="Preencha as informações do novo funcionário"
      />

      <Card>
        <CardContent className="p-6">
          <EmployeeForm
            onSubmit={createEmployeeFn}
            isLoading={isPending}
            categories={categories}
          />
        </CardContent>
      </Card>
    </div>
  );
}
```

### Create Page with Dependencies

```typescript
export default function CreateSupplierPage() {
  const router = useRouter();
  const queryClient = useQueryClient();

  // Create mutation
  const { mutate: createSupplier, isPending } = useMutation({
    mutationFn: createSupplierService,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["suppliers"] });
      toast.success("Fornecedor criado com sucesso!");
      router.push("/fornecedores");
    },
  });

  // Dependencies
  const { data: categories = [] } = useQuery({
    queryKey: ["supplier-categories"],
    queryFn: getSupplierCategories,
  });

  return (
    <SupplierForm
      onSubmit={createSupplier}
      isLoading={isPending}
      categories={categories}
    />
  );
}
```

## ✏️ Edit Page Pattern

### Basic Structure

```typescript
// app/(private)/funcionarios/editar/[id]/page.tsx
import { use } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { getEmployee, updateEmployee } from '@/services/employees';
import { EmployeeForm } from '../../_components/employee-form';

interface Props {
  params: Promise<{ id: string }>;
}

export default function UpdateEmployeePage({ params }: Props) {
  const { id } = use(params);
  const router = useRouter();
  const queryClient = useQueryClient();

  // ✅ Query para buscar recurso específico
  const {
    data: employee,
    isLoading: isLoadingEmployee,
    error
  } = useQuery({
    queryKey: ["employees", id],
    queryFn: () => getEmployee(id),
    enabled: !!id,
  });

  // ✅ Mutation para atualização
  const { mutate: updateEmployeeFn, isPending } = useMutation({
    mutationFn: ({ employeeId, data }: UpdateEmployeePayload) =>
      updateEmployee({ employeeId, data }),
    onSuccess: () => {
      // Invalidate both list and specific item
      queryClient.invalidateQueries({ queryKey: ["employees"] });
      queryClient.invalidateQueries({ queryKey: ["employees", id] });

      toast.success("Funcionário atualizado com sucesso!");
      router.push("/funcionarios");
    },
    onError: (error: Error) => {
      toast.error("Erro ao atualizar funcionário", {
        description: error.message,
      });
    },
  });

  // Handle form submission
  const handleSubmit = (data: UpdateEmployeeInput) => {
    updateEmployeeFn({ employeeId: id, data });
  };

  // Loading state
  if (isLoadingEmployee) {
    return <LoadingSkeleton />;
  }

  // Error state
  if (error || !employee) {
    return <ErrorMessage error={error} />;
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Editar Funcionário"
        description="Atualize as informações do funcionário"
      />

      <Card>
        <CardContent className="p-6">
          <EmployeeForm
            defaultValues={employee}
            onSubmit={handleSubmit}
            isLoading={isPending}
            submitText="Atualizar Funcionário"
          />
        </CardContent>
      </Card>
    </div>
  );
}
```

### Edit Page with Dependencies

```typescript
export default function UpdateSupplierPage({ params }: Props) {
  const { supplierId } = use(params);
  const router = useRouter();
  const queryClient = useQueryClient();

  // Fetch specific supplier
  const { data: supplier, isLoading } = useQuery({
    queryKey: ["supplier", supplierId],
    queryFn: () => getSupplier(supplierId),
    enabled: !!supplierId,
  });

  // Fetch dependencies
  const { data: categories = [] } = useQuery({
    queryKey: ["supplier-categories"],
    queryFn: getSupplierCategories,
  });

  // Update mutation
  const { mutate: updateSupplier, isPending } = useMutation({
    mutationFn: ({ id, data }: UpdateSupplierPayload) =>
      updateSupplierService({ id, data }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["suppliers"] });
      queryClient.invalidateQueries({ queryKey: ["supplier", supplierId] });
      toast.success("Fornecedor atualizado!");
      router.push("/fornecedores");
    },
  });

  if (isLoading) return <LoadingSkeleton />;

  return (
    <SupplierForm
      defaultValues={supplier}
      categories={categories}
      onSubmit={(data) => updateSupplier({ id: supplierId, data })}
      isLoading={isPending}
      submitText="Atualizar Fornecedor"
    />
  );
}
```

## 🔄 Loading & Error States

### Loading Patterns

```typescript
// Page level loading
if (isLoading) {
  return (
    <div className="space-y-6">
      <Skeleton className="h-12 w-64" />
      <Skeleton className="h-96 w-full" />
    </div>
  );
}

// Component level loading
<EmployeesDataTable
  employees={employees}
  isLoading={isLoading}
/>
```

### Error Patterns

```typescript
// Error boundary
if (error) {
  return (
    <div className="text-center py-12">
      <h2 className="text-lg font-semibold">Erro ao carregar dados</h2>
      <p className="text-muted-foreground">{error.message}</p>
      <Button onClick={() => refetch()} className="mt-4">
        Tentar novamente
      </Button>
    </div>
  );
}
```

## 🧭 Navigation Patterns

### Back Button

```typescript
import { ArrowLeft } from 'lucide-react';
import { useRouter } from 'next/navigation';

export function BackButton() {
  const router = useRouter();

  return (
    <Button
      variant="ghost"
      onClick={() => router.back()}
      className="mb-4"
    >
      <ArrowLeft className="mr-2 h-4 w-4" />
      Voltar
    </Button>
  );
}
```

### Breadcrumbs

```typescript
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink } from '@/components/ui/breadcrumb';

export function PageBreadcrumbs({ items }: { items: BreadcrumbItem[] }) {
  return (
    <Breadcrumb>
      {items.map((item, index) => (
        <BreadcrumbItem key={index}>
          <BreadcrumbLink href={item.href}>
            {item.label}
          </BreadcrumbLink>
        </BreadcrumbItem>
      ))}
    </Breadcrumb>
  );
}
```

## 🎯 Best Practices

### ✅ Do's

- Use queries apenas nas pages
- Trate erros no nível da page
- Passe dados via props para componentes
- Use mutations específicas para cada ação
- Invalide cache após mutations
- Forneça feedback ao usuário

### ❌ Don'ts

- Não coloque mutations em componentes de renderização
- Não faça queries em componentes filhos
- Não ignore error states
- Não esqueça de invalidar o cache
- Não faça navegação sem feedback
