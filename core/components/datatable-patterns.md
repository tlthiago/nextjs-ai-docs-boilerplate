# DataTable Patterns

## 🗃️ DataTable Architecture

### Component Structure

```
_components/
├── [resource]-data-table.tsx          # Main table component (pure)
├── [resource]-columns.tsx             # Column definitions
├── [resource]-data-table-row-actions.tsx  # Row actions (mutations)
└── [resource]-stats-cards.tsx         # Statistics cards
```

## 📊 Main DataTable Component

### Pure DataTable Pattern

```typescript
// _components/employees-data-table.tsx
import { DataTable } from '@/components/data-table/data-table';
import { createEmployeeColumns } from './employee-columns';
import { Employee } from '@prisma/client';

interface EmployeesDataTableProps {
  employees: Employee[];
  isLoading?: boolean;
}

export function EmployeesDataTable({
  employees,
  isLoading,
}: EmployeesDataTableProps) {
  // ✅ Pure component - no queries or mutations
  const columns = createEmployeeColumns();

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-96 w-full" />
      </div>
    );
  }

  return (
    <DataTable
      columns={columns}
      data={employees}
      searchKey="name"
      searchPlaceholder="Buscar funcionários..."
      filterableColumns={[
        {
          id: "status",
          title: "Status",
          options: [
            { label: "Ativo", value: "ACTIVE" },
            { label: "Inativo", value: "INACTIVE" },
          ],
        },
        {
          id: "role",
          title: "Função",
          options: [
            { label: "Gerente", value: "MANAGER" },
            { label: "Operador", value: "OPERATOR" },
            { label: "Técnico", value: "TECHNICIAN" },
          ],
        },
      ]}
    />
  );
}
```

### Generic DataTable Component

```typescript
// components/data-table/data-table.tsx
import {
  ColumnDef,
  ColumnFiltersState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  SortingState,
  useReactTable,
} from '@tanstack/react-table';
import { useState } from 'react';
import { DataTableToolbar } from './data-table-toolbar';
import { DataTablePagination } from './data-table-pagination';

interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
  searchKey?: string;
  searchPlaceholder?: string;
  filterableColumns?: FilterableColumn[];
}

interface FilterableColumn {
  id: string;
  title: string;
  options: { label: string; value: string }[];
}

export function DataTable<TData, TValue>({
  columns,
  data,
  searchKey,
  searchPlaceholder = 'Search...',
  filterableColumns = [],
}: DataTableProps<TData, TValue>) {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);

  const table = useReactTable({
    data,
    columns,
    state: {
      sorting,
      columnFilters,
    },
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
  });

  return (
    <div className="space-y-4">
      <DataTableToolbar
        table={table}
        searchKey={searchKey}
        searchPlaceholder={searchPlaceholder}
        filterableColumns={filterableColumns}
      />

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  data-state={row.getIsSelected() && 'selected'}
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center"
                >
                  Nenhum resultado encontrado.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      <DataTablePagination table={table} />
    </div>
  );
}
```

## 📋 Column Definitions

### Basic Column Pattern

```typescript
// _components/employee-columns.tsx
import { ColumnDef } from '@tanstack/react-table';
import { Badge } from '@/components/ui/badge';
import { DataTableColumnHeader } from '@/components/data-table/data-table-column-header';
import { EmployeesDataTableRowActions } from './employees-data-table-row-actions';
import { Employee, Status } from '@prisma/client';

export const createEmployeeColumns = (): ColumnDef<Employee>[] => [
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Nome" />
    ),
    cell: ({ row }) => {
      return (
        <div className="flex items-center">
          <span className="font-medium">{row.original.name}</span>
        </div>
      );
    },
  },
  {
    accessorKey: "email",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Email" />
    ),
    cell: ({ row }) => (
      <span className="text-muted-foreground">{row.original.email}</span>
    ),
  },
  {
    accessorKey: "role",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Função" />
    ),
    cell: ({ row }) => {
      const role = row.original.role;
      const roleLabels = {
        MANAGER: 'Gerente',
        OPERATOR: 'Operador',
        TECHNICIAN: 'Técnico',
      };
      return <span>{roleLabels[role as keyof typeof roleLabels] || role}</span>;
    },
    filterFn: (row, id, value) => {
      return value.includes(row.getValue(id));
    },
  },
  {
    accessorKey: "status",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Status" />
    ),
    cell: ({ row }) => {
      const status = row.getValue("status") as Status;
      return (
        <Badge variant={status === "ACTIVE" ? "default" : "secondary"}>
          {status === "ACTIVE" ? "Ativo" : "Inativo"}
        </Badge>
      );
    },
    filterFn: (row, id, value) => {
      return value.includes(row.getValue(id));
    },
  },
  {
    accessorKey: "createdAt",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Criado em" />
    ),
    cell: ({ row }) => {
      const date = new Date(row.original.createdAt);
      return (
        <span className="text-muted-foreground">
          {date.toLocaleDateString('pt-BR')}
        </span>
      );
    },
  },
  {
    id: "actions",
    cell: ({ row }) => <EmployeesDataTableRowActions row={row} />,
  },
];
```

### Advanced Column Patterns

```typescript
// Custom cell rendering with icons
{
  accessorKey: "type",
  header: "Tipo",
  cell: ({ row }) => {
    const type = row.getValue("type") as string;
    const typeConfig = {
      TRACTOR: { icon: Tractor, label: "Trator", color: "bg-green-100 text-green-800" },
      SPRAYER: { icon: Sprayer, label: "Pulverizador", color: "bg-blue-100 text-blue-800" },
      VEHICLE: { icon: Car, label: "Veículo", color: "bg-yellow-100 text-yellow-800" },
    };

    const config = typeConfig[type as keyof typeof typeConfig];
    if (!config) return <span>{type}</span>;

    const Icon = config.icon;
    return (
      <div className="flex items-center space-x-2">
        <Icon className="h-4 w-4" />
        <Badge className={config.color}>
          {config.label}
        </Badge>
      </div>
    );
  },
}

// Monetary values
{
  accessorKey: "hourlyRate",
  header: ({ column }) => (
    <DataTableColumnHeader column={column} title="Valor/Hora" />
  ),
  cell: ({ row }) => {
    const amount = row.getValue("hourlyRate") as number;
    return (
      <span className="font-mono">
        {new Intl.NumberFormat('pt-BR', {
          style: 'currency',
          currency: 'BRL',
        }).format(amount)}
      </span>
    );
  },
}

// Progress bars
{
  accessorKey: "maintenanceProgress",
  header: "Manutenção",
  cell: ({ row }) => {
    const progress = row.getValue("maintenanceProgress") as number;
    return (
      <div className="flex items-center space-x-2">
        <Progress value={progress} className="w-16" />
        <span className="text-xs text-muted-foreground">{progress}%</span>
      </div>
    );
  },
}
```

## ⚡ Row Actions Component

### Basic RowActions Pattern

```typescript
// _components/employees-data-table-row-actions.tsx
import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { Link } from 'next/link';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
import { Button } from '@/components/ui/button';
import {
  Ellipsis,
  Edit,
  Trash2,
  UserCheck,
  UserX
} from 'lucide-react';
import { Employee } from '@prisma/client';
import { deleteEmployee, toggleEmployeeStatus } from '@/services/employees';

interface DataTableRowActionsProps<TData> {
  row: { original: TData };
}

export function EmployeesDataTableRowActions<TData>({
  row,
}: DataTableRowActionsProps<TData>) {
  const employee = row.original as Employee;
  const queryClient = useQueryClient();
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);

  // ✅ Toggle status mutation
  const { mutateAsync: toggleEmployeeStatusFn, isPending: isToggling } = useMutation({
    mutationFn: toggleEmployeeStatus,
    onSuccess: () => {
      const newStatus = employee.status === 'ACTIVE' ? 'inativado' : 'ativado';
      toast.success(`Funcionário ${newStatus} com sucesso`);
      queryClient.invalidateQueries({ queryKey: ["employees"] });
    },
    onError: (error: Error) => {
      toast.error("Erro ao atualizar status", {
        description: error.message,
      });
    },
  });

  // ✅ Delete mutation
  const { mutateAsync: deleteEmployeeFn, isPending: isDeleting } = useMutation({
    mutationFn: deleteEmployee,
    onSuccess: () => {
      toast.success("Funcionário excluído com sucesso");
      queryClient.invalidateQueries({ queryKey: ["employees"] });
      setShowDeleteDialog(false);
    },
    onError: (error: Error) => {
      toast.error("Erro ao excluir funcionário", {
        description: error.message,
      });
    },
  });

  const handleToggleStatus = async () => {
    await toggleEmployeeStatusFn(employee.id);
  };

  const handleDelete = async () => {
    await deleteEmployeeFn(employee.id);
  };

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          className="flex h-8 w-8 p-0 data-[state=open]:bg-muted"
        >
          <Ellipsis className="h-4 w-4" />
          <span className="sr-only">Abrir menu</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-[160px]">
        {/* Edit Link (não é mutation) */}
        <Link href={`funcionarios/editar/${employee.id}`}>
          <DropdownMenuItem>
            <Edit className="mr-2 h-4 w-4" />
            Editar
          </DropdownMenuItem>
        </Link>

        <DropdownMenuSeparator />

        {/* Toggle Status Mutation */}
        <DropdownMenuItem
          onClick={handleToggleStatus}
          disabled={isToggling}
        >
          {employee.status === 'ACTIVE' ? (
            <>
              <UserX className="mr-2 h-4 w-4" />
              {isToggling ? 'Inativando...' : 'Inativar'}
            </>
          ) : (
            <>
              <UserCheck className="mr-2 h-4 w-4" />
              {isToggling ? 'Ativando...' : 'Ativar'}
            </>
          )}
        </DropdownMenuItem>

        <DropdownMenuSeparator />

        {/* Delete with Confirmation */}
        <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
          <AlertDialogTrigger asChild>
            <DropdownMenuItem
              onSelect={(e) => {
                e.preventDefault();
                setShowDeleteDialog(true);
              }}
              className="text-red-600"
            >
              <Trash2 className="mr-2 h-4 w-4" />
              Excluir
            </DropdownMenuItem>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Excluir Funcionário</AlertDialogTitle>
              <AlertDialogDescription>
                Tem certeza que deseja excluir <strong>{employee.name}</strong>?
                Esta ação não pode ser desfeita.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Cancelar</AlertDialogCancel>
              <AlertDialogAction
                onClick={handleDelete}
                className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                disabled={isDeleting}
              >
                {isDeleting ? 'Excluindo...' : 'Excluir'}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
```

### Advanced RowActions with Multiple Actions

```typescript
export function MachineryDataTableRowActions({ row }: Props) {
  const machinery = row.original as Machinery;
  const queryClient = useQueryClient();

  // Multiple mutations
  const { mutateAsync: toggleStatus } = useMutation({...});
  const { mutateAsync: scheduleMaintenance } = useMutation({...});
  const { mutateAsync: deleteMachinery } = useMutation({...});

  return (
    <DropdownMenu>
      <DropdownMenuContent align="end">
        {/* View Details */}
        <Link href={`maquinarios/${machinery.id}`}>
          <DropdownMenuItem>
            <Eye className="mr-2 h-4 w-4" />
            Ver Detalhes
          </DropdownMenuItem>
        </Link>

        {/* Edit */}
        <Link href={`maquinarios/editar/${machinery.id}`}>
          <DropdownMenuItem>
            <Edit className="mr-2 h-4 w-4" />
            Editar
          </DropdownMenuItem>
        </Link>

        <DropdownMenuSeparator />

        {/* Status Actions */}
        <DropdownMenuItem onClick={() => toggleStatus(machinery.id)}>
          {machinery.status === 'ACTIVE' ? (
            <>
              <Pause className="mr-2 h-4 w-4" />
              Inativar
            </>
          ) : (
            <>
              <Play className="mr-2 h-4 w-4" />
              Ativar
            </>
          )}
        </DropdownMenuItem>

        {/* Maintenance Action */}
        <DropdownMenuItem onClick={() => scheduleMaintenance(machinery.id)}>
          <Wrench className="mr-2 h-4 w-4" />
          Agendar Manutenção
        </DropdownMenuItem>

        <DropdownMenuSeparator />

        {/* Delete with confirmation */}
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <DropdownMenuItem
              onSelect={(e) => e.preventDefault()}
              className="text-red-600"
            >
              <Trash2 className="mr-2 h-4 w-4" />
              Excluir
            </DropdownMenuItem>
          </AlertDialogTrigger>
          {/* ... confirmation dialog ... */}
        </AlertDialog>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
```

## 🎨 Loading States

### Table Loading Skeleton

```typescript
export function TableSkeleton() {
  return (
    <div className="space-y-4">
      {/* Toolbar skeleton */}
      <div className="flex items-center justify-between">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-8 w-32" />
      </div>

      {/* Table skeleton */}
      <div className="rounded-md border">
        <div className="p-4">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="flex items-center space-x-4 py-4">
              <Skeleton className="h-4 w-48" />
              <Skeleton className="h-4 w-32" />
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-4 w-16" />
              <Skeleton className="h-8 w-8" />
            </div>
          ))}
        </div>
      </div>

      {/* Pagination skeleton */}
      <div className="flex items-center justify-between">
        <Skeleton className="h-8 w-48" />
        <div className="flex items-center space-x-2">
          <Skeleton className="h-8 w-20" />
          <Skeleton className="h-8 w-20" />
        </div>
      </div>
    </div>
  );
}
```

## 🎯 DataTable Best Practices

### ✅ Do's

- Mantenha DataTable como componente puro
- Coloque mutations apenas em RowActions
- Use confirmações para ações destrutivas
- Implemente loading states adequados
- Forneça feedback visual para ações
- Use filtros e busca quando apropriado

### ❌ Don'ts

- Não coloque queries no DataTable
- Não coloque mutations no componente principal
- Não esqueça de invalidar cache após mutations
- Não ignore estados de loading
- Não implemente ações sem confirmação
- Não sobrecarregue com muitos filtros
