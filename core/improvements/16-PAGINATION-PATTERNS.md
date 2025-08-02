# 📄 Avocado HP - Padrões de Paginação

### **Query Parameters Pattern**

```
GET /api/v1/properties/employees?page=1&limit=20&search=john&status=ACTIVE&createdAfter=2024-01-01
```

**Standard Parameters:**

- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)
- `search`: Text search across multiple fields
- `sortBy`: Field to sort by
- `sortOrder`: 'asc' or 'desc' (default: 'desc')

**Entity-specific filters:** Vary by resource (status, category, dates, etc.)

### **Response Patterns**

#### **Success - Resource List (200)**

```typescript
{
  data: {
    items: T[],
    pagination: {
      page: number,
      limit: number,
      total: number,
      totalPages: number,
      hasNextPage: boolean,
      hasPrevPage: boolean
    }
  },
  message?: string
}
```

## **Estratégia de Paginação**

### **Arquitetura Frontend + Backend**

```typescript
// Frontend: useUrlPagination hook gerencia URL state
// Backend: Cursor-based pagination com Prisma
// Sync: URL params ↔ TanStack Query ↔ Server state
```

### **Fluxo de Dados**

```
1. URL Params      → useUrlPagination hook
2. Query State     → TanStack Query (cache + fetch)
3. Server Request  → API endpoint com filtros
4. Database Query  → Prisma cursor pagination
5. Response        → Cached data + URL sync
```

## **1. Frontend Pagination Hook**

### **URL-Synchronized Pagination**

```typescript
// hooks/use-url-pagination.ts
"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useMemo, useCallback } from "react";

export interface PaginationState {
  page: number;
  pageSize: number;
  search?: string;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
  filters: Record<string, string | string[]>;
}

export interface PaginationActions {
  setPage: (page: number) => void;
  setPageSize: (size: number) => void;
  setSearch: (search: string) => void;
  setSorting: (sortBy: string, sortOrder: "asc" | "desc") => void;
  setFilter: (key: string, value: string | string[] | null) => void;
  reset: () => void;
}

export function useUrlPagination(
  defaultPageSize = 10,
): PaginationState & PaginationActions {
  const router = useRouter();
  const searchParams = useSearchParams();

  // Parse current state from URL
  const state = useMemo((): PaginationState => {
    const page = parseInt(searchParams.get("page") || "1", 10);
    const pageSize = parseInt(
      searchParams.get("pageSize") || defaultPageSize.toString(),
      10,
    );
    const search = searchParams.get("search") || "";
    const sortBy = searchParams.get("sortBy") || undefined;
    const sortOrder =
      (searchParams.get("sortOrder") as "asc" | "desc") || "asc";

    // Parse filters (exclude pagination/search params)
    const filters: Record<string, string | string[]> = {};
    for (const [key, value] of searchParams.entries()) {
      if (
        !["page", "pageSize", "search", "sortBy", "sortOrder"].includes(key)
      ) {
        const existing = filters[key];
        if (existing) {
          filters[key] = Array.isArray(existing)
            ? [...existing, value]
            : [existing, value];
        } else {
          filters[key] = value;
        }
      }
    }

    return { page, pageSize, search, sortBy, sortOrder, filters };
  }, [searchParams, defaultPageSize]);

  // Update URL with new params
  const updateUrl = useCallback(
    (updates: Partial<PaginationState>) => {
      const params = new URLSearchParams(searchParams);

      // Apply updates
      Object.entries(updates).forEach(([key, value]) => {
        if (key === "filters" && value && typeof value === "object") {
          // Clear existing filters first
          for (const filterKey of Object.keys(state.filters)) {
            params.delete(filterKey);
          }
          // Add new filters
          Object.entries(value).forEach(([filterKey, filterValue]) => {
            if (filterValue === null || filterValue === undefined) {
              params.delete(filterKey);
            } else if (Array.isArray(filterValue)) {
              params.delete(filterKey);
              filterValue.forEach((v) => params.append(filterKey, v));
            } else {
              params.set(filterKey, filterValue.toString());
            }
          });
        } else if (value === null || value === undefined || value === "") {
          params.delete(key);
        } else {
          params.set(key, value.toString());
        }
      });

      // Reset to page 1 when changing filters/search/sorting
      if ("search" in updates || "filters" in updates || "sortBy" in updates) {
        params.set("page", "1");
      }

      router.push(`?${params.toString()}`, { scroll: false });
    },
    [router, searchParams, state.filters],
  );

  // Actions
  const setPage = useCallback(
    (page: number) => updateUrl({ page }),
    [updateUrl],
  );
  const setPageSize = useCallback(
    (pageSize: number) => updateUrl({ pageSize, page: 1 }),
    [updateUrl],
  );
  const setSearch = useCallback(
    (search: string) => updateUrl({ search }),
    [updateUrl],
  );
  const setSorting = useCallback(
    (sortBy: string, sortOrder: "asc" | "desc") =>
      updateUrl({ sortBy, sortOrder }),
    [updateUrl],
  );
  const setFilter = useCallback(
    (key: string, value: string | string[] | null) => {
      const newFilters = { ...state.filters };
      if (value === null) {
        delete newFilters[key];
      } else {
        newFilters[key] = value;
      }
      updateUrl({ filters: newFilters });
    },
    [updateUrl, state.filters],
  );
  const reset = useCallback(() => {
    router.push(window.location.pathname, { scroll: false });
  }, [router]);

  return {
    ...state,
    setPage,
    setPageSize,
    setSearch,
    setSorting,
    setFilter,
    reset,
  };
}
```

### **TanStack Query Integration**

```typescript
// hooks/use-suppliers.ts
"use client";

import { useQuery } from "@tanstack/react-query";
import { useUrlPagination } from "./use-url-pagination";
import { SupplierService } from "@/services/suppliers";

export function useSuppliersPaginated() {
  const pagination = useUrlPagination(10);

  const query = useQuery({
    queryKey: ["suppliers", "paginated", pagination],
    queryFn: () =>
      SupplierService.findManyPaginated({
        page: pagination.page,
        pageSize: pagination.pageSize,
        search: pagination.search,
        sortBy: pagination.sortBy,
        sortOrder: pagination.sortOrder,
        filters: pagination.filters,
      }),
    keepPreviousData: true, // Smooth transitions between pages
    staleTime: 30000, // 30 seconds
  });

  return {
    ...query,
    pagination,
  };
}
```

## **2. Backend Pagination Service**

### **Service Layer Implementation**

```typescript
// services/suppliers/index.ts
import { prisma } from "@/lib/prisma";
import { Supplier, Prisma } from "@prisma/client";

export interface PaginationFilters {
  page: number;
  pageSize: number;
  search?: string;
  sortBy?: string;
  sortOrder?: "asc" | "desc";
  filters: Record<string, string | string[]>;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  };
}

export class SupplierService {
  static async findManyPaginated(
    filters: PaginationFilters,
  ): Promise<PaginatedResponse<SupplierWithCategories>> {
    const {
      page,
      pageSize,
      search,
      sortBy,
      sortOrder,
      filters: customFilters,
    } = filters;

    // Build where clause
    const where: Prisma.SupplierWhereInput = {
      deletedAt: null, // Soft delete filter
    };

    // Search functionality
    if (search) {
      where.OR = [
        { name: { contains: search, mode: "insensitive" } },
        { email: { contains: search, mode: "insensitive" } },
        { phone: { contains: search, mode: "insensitive" } },
      ];
    }

    // Custom filters
    if (customFilters.categories) {
      const categoryIds = Array.isArray(customFilters.categories)
        ? customFilters.categories
        : [customFilters.categories];

      where.categories = {
        some: {
          categoryId: { in: categoryIds },
        },
      };
    }

    if (customFilters.status) {
      where.status = customFilters.status as SupplierStatus;
    }

    // Sorting
    const orderBy: Prisma.SupplierOrderByWithRelationInput = {};
    if (sortBy) {
      if (sortBy === "categoriesCount") {
        orderBy.categories = { _count: sortOrder };
      } else {
        orderBy[sortBy as keyof Supplier] = sortOrder;
      }
    } else {
      orderBy.createdAt = "desc"; // Default sort
    }

    // Execute queries in parallel
    const [data, total] = await Promise.all([
      prisma.supplier.findMany({
        where,
        orderBy,
        skip: (page - 1) * pageSize,
        take: pageSize,
        include: {
          categories: {
            include: {
              category: true,
            },
          },
          _count: {
            select: {
              categories: true,
            },
          },
        },
      }),
      prisma.supplier.count({ where }),
    ]);

    // Calculate pagination metadata
    const totalPages = Math.ceil(total / pageSize);
    const hasNextPage = page < totalPages;
    const hasPreviousPage = page > 1;

    return {
      data,
      meta: {
        page,
        pageSize,
        total,
        totalPages,
        hasNextPage,
        hasPreviousPage,
      },
    };
  }
}
```

### **API Route Implementation**

```typescript
// app/api/v1/suppliers/route.ts
import { NextRequest, NextResponse } from "next/server";
import { SupplierService } from "@/services/suppliers";
import { validatePaginationParams } from "@/lib/validation";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);

    // Parse and validate pagination parameters
    const paginationParams = validatePaginationParams({
      page: searchParams.get("page"),
      pageSize: searchParams.get("pageSize"),
      search: searchParams.get("search"),
      sortBy: searchParams.get("sortBy"),
      sortOrder: searchParams.get("sortOrder"),
      // Extract filter parameters
      categories: searchParams.getAll("categories"),
      status: searchParams.get("status"),
    });

    const result = await SupplierService.findManyPaginated(paginationParams);

    // Add pagination headers
    const response = NextResponse.json(result);
    response.headers.set("X-Total-Count", result.meta.total.toString());
    response.headers.set("X-Page", result.meta.page.toString());
    response.headers.set("X-Page-Size", result.meta.pageSize.toString());
    response.headers.set("X-Total-Pages", result.meta.totalPages.toString());

    return response;
  } catch (error) {
    console.error("Error fetching suppliers:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
```

## **3. Data Table Integration**

### **Paginated Data Table Component**

```typescript
// components/data-table/paginated-data-table.tsx
"use client";

import { DataTable } from "./data-table";
import { DataTablePagination } from "./data-table-pagination";
import { DataTableToolbar } from "./data-table-toolbar";
import { useSuppliersPaginated } from "@/hooks/use-suppliers";
import { supplierColumns } from "./columns";

export function PaginatedSuppliersTable() {
  const { data, isLoading, error, pagination } = useSuppliersPaginated();

  if (error) {
    return <div>Error loading suppliers</div>;
  }

  return (
    <div className="space-y-4">
      <DataTableToolbar
        search={pagination.search}
        onSearchChange={pagination.setSearch}
        filters={pagination.filters}
        onFilterChange={pagination.setFilter}
        onReset={pagination.reset}
      />

      <DataTable
        columns={supplierColumns}
        data={data?.data || []}
        isLoading={isLoading}
      />

      <DataTablePagination
        page={pagination.page}
        pageSize={pagination.pageSize}
        total={data?.meta.total || 0}
        totalPages={data?.meta.totalPages || 0}
        hasNextPage={data?.meta.hasNextPage || false}
        hasPreviousPage={data?.meta.hasPreviousPage || false}
        onPageChange={pagination.setPage}
        onPageSizeChange={pagination.setPageSize}
      />
    </div>
  );
}
```

### **Pagination Component**

```typescript
// components/data-table/data-table-pagination.tsx
"use client";

import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from "lucide-react";

interface DataTablePaginationProps {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
  onPageChange: (page: number) => void;
  onPageSizeChange: (pageSize: number) => void;
}

export function DataTablePagination({
  page,
  pageSize,
  total,
  totalPages,
  hasNextPage,
  hasPreviousPage,
  onPageChange,
  onPageSizeChange,
}: DataTablePaginationProps) {
  return (
    <div className="flex items-center justify-between px-2">
      <div className="flex-1 text-sm text-muted-foreground">
        {total > 0 ? (
          <>
            Mostrando {(page - 1) * pageSize + 1} a{" "}
            {Math.min(page * pageSize, total)} de {total} resultado(s).
          </>
        ) : (
          "Nenhum resultado encontrado."
        )}
      </div>

      <div className="flex items-center space-x-6 lg:space-x-8">
        <div className="flex items-center space-x-2">
          <p className="text-sm font-medium">Linhas por página</p>
          <Select
            value={`${pageSize}`}
            onValueChange={(value) => onPageSizeChange(Number(value))}
          >
            <SelectTrigger className="h-8 w-[70px]">
              <SelectValue placeholder={pageSize} />
            </SelectTrigger>
            <SelectContent side="top">
              {[10, 20, 30, 40, 50].map((size) => (
                <SelectItem key={size} value={`${size}`}>
                  {size}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="flex w-[100px] items-center justify-center text-sm font-medium">
          Página {page} de {totalPages}
        </div>

        <div className="flex items-center space-x-2">
          <Button
            variant="outline"
            className="hidden h-8 w-8 p-0 lg:flex"
            onClick={() => onPageChange(1)}
            disabled={!hasPreviousPage}
          >
            <span className="sr-only">Ir para primeira página</span>
            <ChevronsLeft className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            className="h-8 w-8 p-0"
            onClick={() => onPageChange(page - 1)}
            disabled={!hasPreviousPage}
          >
            <span className="sr-only">Ir para página anterior</span>
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            className="h-8 w-8 p-0"
            onClick={() => onPageChange(page + 1)}
            disabled={!hasNextPage}
          >
            <span className="sr-only">Ir para próxima página</span>
            <ChevronRight className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            className="hidden h-8 w-8 p-0 lg:flex"
            onClick={() => onPageChange(totalPages)}
            disabled={!hasNextPage}
          >
            <span className="sr-only">Ir para última página</span>
            <ChevronsRight className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}
```

## **4. Advanced Filtering**

### **Multi-Select Filter Component**

```typescript
// components/data-table/filters/multi-select-filter.tsx
"use client";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem } from "@/components/ui/command";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Separator } from "@/components/ui/separator";
import { Check, PlusCircle, X } from "lucide-react";
import { useState } from "react";

interface FilterOption {
  label: string;
  value: string;
  icon?: React.ComponentType<{ className?: string }>;
}

interface MultiSelectFilterProps {
  title: string;
  options: FilterOption[];
  selectedValues: string[];
  onSelectionChange: (values: string[]) => void;
}

export function MultiSelectFilter({
  title,
  options,
  selectedValues,
  onSelectionChange,
}: MultiSelectFilterProps) {
  const [open, setOpen] = useState(false);

  const selectedOptions = options.filter((option) =>
    selectedValues.includes(option.value)
  );

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button variant="outline" size="sm" className="h-8 border-dashed">
          <PlusCircle className="mr-2 h-4 w-4" />
          {title}
          {selectedValues.length > 0 && (
            <>
              <Separator orientation="vertical" className="mx-2 h-4" />
              <Badge
                variant="secondary"
                className="rounded-sm px-1 font-normal lg:hidden"
              >
                {selectedValues.length}
              </Badge>
              <div className="hidden space-x-1 lg:flex">
                {selectedValues.length > 2 ? (
                  <Badge
                    variant="secondary"
                    className="rounded-sm px-1 font-normal"
                  >
                    {selectedValues.length} selected
                  </Badge>
                ) : (
                  selectedOptions.map((option) => (
                    <Badge
                      variant="secondary"
                      key={option.value}
                      className="rounded-sm px-1 font-normal"
                    >
                      {option.label}
                    </Badge>
                  ))
                )}
              </div>
            </>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[200px] p-0" align="start">
        <Command>
          <CommandInput placeholder={`Buscar ${title.toLowerCase()}...`} />
          <CommandEmpty>Nenhum resultado encontrado.</CommandEmpty>
          <CommandGroup>
            {options.map((option) => {
              const isSelected = selectedValues.includes(option.value);
              return (
                <CommandItem
                  key={option.value}
                  onSelect={() => {
                    if (isSelected) {
                      onSelectionChange(
                        selectedValues.filter((value) => value !== option.value)
                      );
                    } else {
                      onSelectionChange([...selectedValues, option.value]);
                    }
                  }}
                >
                  <div
                    className={`mr-2 flex h-4 w-4 items-center justify-center rounded-sm border border-primary ${
                      isSelected
                        ? "bg-primary text-primary-foreground"
                        : "opacity-50 [&_svg]:invisible"
                    }`}
                  >
                    <Check className="h-4 w-4" />
                  </div>
                  {option.icon && (
                    <option.icon className="mr-2 h-4 w-4 text-muted-foreground" />
                  )}
                  <span>{option.label}</span>
                </CommandItem>
              );
            })}
          </CommandGroup>
          {selectedValues.length > 0 && (
            <>
              <Separator />
              <CommandGroup>
                <CommandItem
                  onSelect={() => onSelectionChange([])}
                  className="justify-center text-center"
                >
                  Limpar filtros
                </CommandItem>
              </CommandGroup>
            </>
          )}
        </Command>
      </PopoverContent>
    </Popover>
  );
}
```

### **Search and Filter Toolbar**

```typescript
// components/data-table/data-table-toolbar.tsx
"use client";

import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { MultiSelectFilter } from "./filters/multi-select-filter";
import { X } from "lucide-react";

interface DataTableToolbarProps {
  search: string;
  onSearchChange: (search: string) => void;
  filters: Record<string, string | string[]>;
  onFilterChange: (key: string, value: string[] | null) => void;
  onReset: () => void;
}

export function DataTableToolbar({
  search,
  onSearchChange,
  filters,
  onFilterChange,
  onReset,
}: DataTableToolbarProps) {
  const isFiltered = search || Object.keys(filters).length > 0;

  return (
    <div className="flex items-center justify-between">
      <div className="flex flex-1 items-center space-x-2">
        <Input
          placeholder="Buscar fornecedores..."
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          className="h-8 w-[150px] lg:w-[250px]"
        />

        <MultiSelectFilter
          title="Categorias"
          options={[
            { label: "Equipamentos", value: "equipamentos" },
            { label: "Peças", value: "pecas" },
            { label: "Serviços", value: "servicos" },
          ]}
          selectedValues={
            Array.isArray(filters.categories)
              ? filters.categories
              : filters.categories
              ? [filters.categories]
              : []
          }
          onSelectionChange={(values) =>
            onFilterChange("categories", values.length > 0 ? values : null)
          }
        />

        {isFiltered && (
          <Button
            variant="ghost"
            onClick={onReset}
            className="h-8 px-2 lg:px-3"
          >
            Limpar
            <X className="ml-2 h-4 w-4" />
          </Button>
        )}
      </div>
    </div>
  );
}
```

## **5. Performance Optimizations**

### **Query Key Management**

```typescript
// lib/query-keys.ts
export const createQueryKeys = <T extends string>(prefix: T) => ({
  all: [prefix] as const,
  lists: () => [...createQueryKeys(prefix).all, "list"] as const,
  list: (filters: unknown) =>
    [...createQueryKeys(prefix).lists(), filters] as const,
  details: () => [...createQueryKeys(prefix).all, "detail"] as const,
  detail: (id: string) => [...createQueryKeys(prefix).details(), id] as const,
});

export const supplierKeys = createQueryKeys("suppliers");
export const employeeKeys = createQueryKeys("employees");
```

### **Debounced Search Hook**

```typescript
// hooks/use-debounced-value.ts
"use client";

import { useState, useEffect } from "react";

export function useDebouncedValue<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// Usage in search
export function useSearchPagination() {
  const pagination = useUrlPagination();
  const debouncedSearch = useDebouncedValue(pagination.search, 300);

  return {
    ...pagination,
    debouncedSearch,
  };
}
```

## 📖 **Referências Cruzadas**

### **Documentação Relacionada**

- **[02-ARCHITECTURE.md](./02-ARCHITECTURE-NEW.md)**: Performance e otimização
- **[06-API-PATTERNS.md](./06-API-PATTERNS.md)**: API endpoints e responses
- **[07-DATA-PATTERNS.md](./07-DATA-PATTERNS.md)**: Service layer e Prisma queries
- **[08-ERROR-HANDLING.md](./08-ERROR-HANDLING.md)**: Error states na paginação
- **[15-COMPONENT-PATTERNS.md](./15-COMPONENT-PATTERNS.md)**: Data tables e hooks

### **Fluxo de Paginação**

```
1. URL State        → useUrlPagination (URL params)
2. Query Hook       → TanStack Query (cache + fetch)
3. API Request      → HTTP endpoints com filtros
4. Service Layer    → PAGINATION-PATTERNS (este arquivo)
5. Database Query   → DATA-PATTERNS (Prisma pagination)
6. Component Render → COMPONENT-PATTERNS (data tables)
```

### **Responsabilidades**

- **PAGINATION-PATTERNS**: URL sync, filtros, paginação servidor/cliente
- **COMPONENT-PATTERNS**: Data tables, hooks React, UI components
- **DATA-PATTERNS**: Service layer, validação, queries Prisma
- **API-PATTERNS**: HTTP endpoints, responses paginadas
- **ERROR-HANDLING**: Estados de erro em listas paginadas

### **Query Parameters Parser**

```typescript
// lib/api/parse-query-params.ts
export function parseQueryParams(url: string) {
  const { searchParams } = new URL(url);

  return {
    // Pagination
    page: parseInt(searchParams.get("page") || "1"),
    limit: Math.min(parseInt(searchParams.get("limit") || "20"), 100),

    // Search
    search: searchParams.get("search") || undefined,

    // Filters
    status: searchParams.get("status") || undefined,

    // Arrays
    categoryIds: searchParams.getAll("categoryIds"),

    // Dates
    createdAfter: searchParams.get("createdAfter") || undefined,
    createdBefore: searchParams.get("createdBefore") || undefined,

    // Sorting
    sortBy: searchParams.get("sortBy") || "createdAt",
    sortOrder: (searchParams.get("sortOrder") || "desc") as "asc" | "desc",
  };
}
```

## **Pagination Patterns**

### **Offset-based Pagination (Padrão)**

```typescript
interface PaginationParams {
  page?: number;
  limit?: number;
}

export async function getPaginatedResources({
  page = 1,
  limit = 20,
  filters = {},
}: PaginationParams & { filters?: any }) {
  const skip = (page - 1) * limit;
  const maxLimit = Math.min(limit, 100); // Máximo 100 itens

  const whereClause = {
    status: { not: "DELETED" },
    ...buildFilters(filters),
  };

  const [items, total] = await Promise.all([
    prisma.resource.findMany({
      where: whereClause,
      skip,
      take: maxLimit,
      orderBy: { createdAt: "desc" },
      include: {
        createdBy: { select: { id: true, name: true } },
      },
    }),
    prisma.resource.count({ where: whereClause }),
  ]);

  return {
    items,
    pagination: {
      page,
      limit: maxLimit,
      total,
      totalPages: Math.ceil(total / maxLimit),
      hasNextPage: page * maxLimit < total,
      hasPrevPage: page > 1,
    },
  };
}
```

### **Cursor-based Pagination (Performance crítica)**

```typescript
export async function getCursorPaginatedResources({
  cursor,
  limit = 20,
  filters = {},
}: {
  cursor?: string;
  limit?: number;
  filters?: any;
}) {
  const maxLimit = Math.min(limit, 100);

  const items = await prisma.resource.findMany({
    where: {
      status: { not: "DELETED" },
      ...buildFilters(filters),
    },
    take: maxLimit + 1, // +1 para verificar se há próxima página
    skip: cursor ? 1 : 0,
    cursor: cursor ? { id: cursor } : undefined,
    orderBy: { createdAt: "desc" },
  });

  const hasNextPage = items.length > maxLimit;
  const data = hasNextPage ? items.slice(0, -1) : items;

  return {
    items: data,
    pagination: {
      hasNextPage,
      nextCursor: hasNextPage ? data[data.length - 1].id : null,
    },
  };
}
```

### **Count Otimizado para Paginação**

```typescript
const [items, total] = await Promise.all([
  prisma.supplier.findMany({
    where: whereClause,
    skip,
    take: limit,
    // Buscar com relacionamentos
    include: { categories: true },
  }),
  prisma.supplier.count({
    where: whereClause, // Mesmo where, mas sem include
  }),
]);
```

## **Query Optimization**

### **Include Seletivo**

```typescript
// Include seletivo - apenas dados necessários
const suppliers = await prisma.supplier.findMany({
  where: { status: { not: "DELETED" } },
  select: {
    id: true,
    name: true,
    email: true,
    status: true,
    createdAt: true,
    // Relacionamentos seletivos
    createdBy: {
      select: { id: true, name: true },
    },
    categories: {
      where: { status: { not: "DELETED" } },
      select: {
        category: {
          select: { id: true, name: true },
        },
      },
    },
  },
});
```

### **Read Operations com Filtros**

```typescript
// services/suppliers/get-suppliers.ts
import { SupplierFiltersSchema, type SupplierFilters } from "./schemas";

interface GetSuppliersOptions {
  filters?: SupplierFilters;
  page?: number;
  limit?: number;
  include?: string[];
}

export async function getSuppliers(
  options: GetSuppliersOptions = {},
): Promise<{ data: SupplierWithCategories[]; meta: PaginationMeta }> {
  const { filters, page, limit, include } = options;

  // Construção dos query parameters
  const queryParams = new URLSearchParams();

  // Paginação
  if (page) queryParams.set("page", page.toString());
  if (limit) queryParams.set("limit", limit.toString());

  // Relacionamentos
  if (include?.length) {
    queryParams.set("include", include.join(","));
  }

  // Filtros dinâmicos
  Object.entries(filters || {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") {
      if (Array.isArray(value)) {
        queryParams.set(key, value.join(","));
      } else {
        queryParams.set(key, value.toString());
      }
    }
  });

  const url = `/api/v1/suppliers${queryParams.toString() ? `?${queryParams.toString()}` : ""}`;

  const response = await fetch(url, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    return handleServiceError(response);
  }

  return response.json();
}

// Exemplo de uso específico para busca por nome
export async function searchSuppliersByName(
  name: string,
): Promise<SupplierWithCategories[]> {
  const result = await getSuppliers({
    filters: { name },
    include: ["categories"],
  });

  return result.data;
}
```

### **Get Single Resource**

```typescript
// services/suppliers/get-supplier.ts
interface GetSupplierOptions {
  include?: string[];
}

export async function getSupplier(
  supplierId: string,
  options: GetSupplierOptions = {},
): Promise<SupplierWithCategories> {
  const queryParams = new URLSearchParams();

  if (options.include?.length) {
    queryParams.set("include", options.include.join(","));
  }

  const url = `/api/v1/suppliers/${supplierId}${queryParams.toString() ? `?${queryParams.toString()}` : ""}`;

  const response = await fetch(url, {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    return handleServiceError(response);
  }

  return response.json();
}
```

## **2. Schemas Zod para Tipagem**

### **Schemas de Entrada**

```typescript
// services/suppliers/schemas.ts
import { z } from "zod";

// Schema para filtros de busca
export const SupplierFiltersSchema = z
  .object({
    name: z.string().optional(),
    email: z.string().optional(),
    status: z.enum(["ACTIVE", "INACTIVE"]).optional(),
    categoryIds: z.array(z.string().cuid()).optional(),
    createdAfter: z.string().datetime().optional(),
    createdBefore: z.string().datetime().optional(),
  })
  .optional();

// Types exportados para tipagem TypeScript
export type SupplierFilters = z.infer<typeof SupplierFiltersSchema>;
```

## **3. Utilitários para Query Parameters**

### **Helper para Construção de URLs**

```typescript
// services/shared/query-builder.ts
export interface QueryOptions {
  page?: number;
  limit?: number;
  include?: string[];
  filters?: Record<string, any>;
}

export function buildQueryString(options: QueryOptions): string {
  const params = new URLSearchParams();

  if (options.page) params.set("page", options.page.toString());
  if (options.limit) params.set("limit", options.limit.toString());
  if (options.include?.length) params.set("include", options.include.join(","));

  // Adiciona filtros dinâmicos
  if (options.filters) {
    Object.entries(options.filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== "") {
        if (Array.isArray(value)) {
          params.set(key, value.join(","));
        } else {
          params.set(key, value.toString());
        }
      }
    });
  }

  const queryString = params.toString();
  return queryString ? `?${queryString}` : "";
}

// Exemplo de uso
export function buildApiUrl(
  endpoint: string,
  options: QueryOptions = {},
): string {
  return `${endpoint}${buildQueryString(options)}`;
}
```
