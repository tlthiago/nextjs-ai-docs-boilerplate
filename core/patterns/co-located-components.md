# 🧩 Co-located Components Pattern

## **Filosofia: Componentes Próximos ao Uso**

O projeto Avocado HP adota o padrão **co-located components**, onde componentes específicos de um recurso ficam organizados junto às páginas que os utilizam, em vez de uma pasta central de componentes.

### **Estrutura por Recurso**

```
fornecedores/                    # Recurso principal
├── (categorias)/                # Sub-recurso (Route Group)
│   ├── _components/             # Componentes específicos do sub-recurso
│   │   ├── category-data-table.tsx  # Tabela de categorias
│   │   ├── category-columns.tsx     # Definição das colunas
│   │   ├── category-form.tsx        # Formulário de categoria
│   │   └── category-stats-cards.tsx # Cards de estatísticas
│   ├── adicionar/
│   │   └── page.tsx             # Import: ../_components/category-form
│   ├── editar/[categoryId]/
│   │   └── page.tsx             # Import: ../../_components/category-form
│   └── page.tsx                 # Import: ./_components/category-data-table
├── _components/                 # Componentes específicos do recurso principal
│   ├── supplier-data-table.tsx  # Tabela de fornecedores
│   ├── supplier-columns.tsx     # Definição das colunas
│   ├── supplier-form.tsx        # Formulário de fornecedor
│   └── supplier-stats-cards.tsx # Cards de estatísticas
├── adicionar/
│   └── page.tsx                 # Import: ../_components/supplier-form
├── editar/[supplierId]/
│   └── page.tsx                 # Import: ../../_components/supplier-form
└── page.tsx                     # Import: ./_components/supplier-data-table
```

### **URLs Geradas pela Estrutura**

```
# Recurso Principal (Fornecedores)
/fornecedores                    # Listagem de fornecedores
/fornecedores/adicionar          # Criar novo fornecedor
/fornecedores/editar/[id]        # Editar fornecedor específico

# Sub-recurso (Categorias de Fornecedores)
/fornecedores/categorias         # Listagem de categorias
/fornecedores/categorias/adicionar      # Criar nova categoria
/fornecedores/categorias/editar/[id]    # Editar categoria específica
```

## **Vantagens do Co-location**

### **✅ Manutenibilidade**

- **Proximidade**: Componentes ficam próximos ao código que os usa
- **Refatoração**: Fácil de mover/renomear recursos completos
- **Descoberta**: Desenvolvedores encontram componentes naturalmente
- **Escopo**: Reduz confusão sobre onde componentes são usados

### **✅ Imports Limpos**

```typescript
// ✅ Co-located (atual)
import { SupplierDataTable } from "./_components/supplier-data-table";
import { SupplierStatsCards } from "./_components/supplier-stats-cards";

// ❌ Centralizado (evitado)
import { SupplierDataTable } from "../../../../components/suppliers/supplier-data-table";
import { SupplierStatsCards } from "../../../../components/suppliers/supplier-stats-cards";
```

### **✅ Domain-Driven Organization**

- **Coesão**: Componentes relacionados ficam juntos
- **Separação**: Cada recurso mantém suas responsabilidades
- **Escalabilidade**: Padrão replicável para novos recursos

### **✅ Performance Benefits**

- **Bundle Splitting**: Componentes carregados apenas quando necessários
- **Tree Shaking**: Eliminação automática de código não usado
- **Code Splitting**: Divisão natural por feature/recurso
- **Lazy Loading**: Carregamento sob demanda de recursos

## **Quando Usar Cada Abordagem**

### **📁 `app/resource/_components/` (Co-located)**

- Componentes específicos do recurso
- Data tables customizadas
- Formulários específicos
- Cards de estatísticas do domínio
- Componentes que não são reutilizados
- Hooks específicos do recurso
- Utilitários específicos da feature

### **📁 `src/components/` (Global)**

- Componentes UI base (Button, Input, Dialog)
- Componentes reutilizados entre recursos
- Layouts e navegação
- Utilitários visuais genéricos
- Sistema de design (Shadcn UI)
- Componentes de infraestrutura

## **Convenções de Nomenclatura**

### **Componentes Co-located**

```typescript
// Padrão: [resource]-[type].tsx
supplier - data - table.tsx; // Tabela específica de fornecedores
supplier - form.tsx; // Formulário específico de fornecedores
supplier - stats - cards.tsx; // Cards específicos de fornecedores
employee - data - table.tsx; // Tabela específica de funcionários
employee - form.tsx; // Formulário específico de funcionários

// Sub-recursos: [sub-resource]-[type].tsx
category - data - table.tsx; // Tabela de categorias (sub-recurso)
category - form.tsx; // Formulário de categorias (sub-recurso)
department - data - table.tsx; // Tabela de departamentos (sub-recurso)
```

### **Hooks Co-located**

```typescript
// hooks específicos do recurso
use - suppliers.ts; // Hook para gerenciar suppliers
use - supplier - form.ts; // Hook para formulário de supplier
use - categories.ts; // Hook para gerenciar categories
```

### **Utilitários Co-located**

```typescript
// utils específicos do recurso
supplier - utils.ts; // Utilitários específicos de suppliers
category - helpers.ts; // Helpers específicos de categories
```

## **Padrão de Sub-recursos**

Sub-recursos são entidades relacionadas que possuem estrutura CRUD completa dentro do contexto do recurso pai.

### **Estrutura Completa de Sub-recurso**

```
fornecedores/
├── (categorias)/              # Route Group para sub-recurso
│   ├── _components/           # Componentes específicos
│   │   ├── category-data-table.tsx
│   │   ├── category-form.tsx
│   │   ├── category-stats-cards.tsx
│   │   └── hooks/
│   │       └── use-categories.ts
│   ├── adicionar/page.tsx     # Criar categoria
│   ├── editar/[id]/page.tsx   # Editar categoria
│   └── page.tsx               # Listar categorias
└── page.tsx                   # Página principal (pode incluir tabs)
```

### **Integração com Recurso Principal**

```typescript
// fornecedores/page.tsx - Página principal com tabs
export default function SuppliersPage() {
  return (
    <Tabs defaultValue="suppliers">
      <TabsList>
        <TabsTrigger value="suppliers">Fornecedores</TabsTrigger>
        <TabsTrigger value="categories">Categorias</TabsTrigger>
      </TabsList>

      <TabsContent value="suppliers">
        <SuppliersDataTable />
      </TabsContent>

      <TabsContent value="categories">
        {/* Pode incluir CategoriesDataTable ou Link para /categorias */}
        <CategoriesDataTable />
      </TabsContent>
    </Tabs>
  );
}
```

### **Casos de Uso para Sub-recursos**

- **Categorias de Fornecedores**: Classificações para organizar fornecedores
- **Departamentos de Funcionários**: Divisões organizacionais
- **Tipos de Máquinas**: Classificações de equipamentos
- **Configurações de Sistema**: Opções relacionadas a um módulo
- **Histórico de Transações**: Registros relacionados a uma entidade
- **Anexos/Documentos**: Arquivos relacionados a um recurso

### **Vantagens dos Sub-recursos**

- **Contexto Preservado**: URLs mantêm hierarquia (`/fornecedores/categorias`)
- **Organização**: Entidades relacionadas ficam próximas
- **Navegação**: Breadcrumbs e navegação intuitivos
- **Permissões**: Controle de acesso baseado em hierarquia
- **SEO**: URLs semânticas e organizadas
- **Manutenção**: Facilita refatoração de módulos completos

## **Estrutura Replicável**

Todos os recursos seguem o mesmo padrão, incluindo sub-recursos quando aplicável:

### **Recursos Principais**

```
fornecedores/               funcionarios/             maquinas/
├── (categorias)/          ├── (departamentos)/      ├── (tipos)/
│   ├── _components/       │   ├── _components/      │   ├── _components/
│   ├── adicionar/         │   ├── adicionar/        │   ├── adicionar/
│   ├── editar/[id]/       │   ├── editar/[id]/      │   ├── editar/[id]/
│   └── page.tsx           │   └── page.tsx          │   └── page.tsx
├── _components/           ├── _components/          ├── _components/
│   ├── supplier-table.tsx │   ├── employee-table.tsx│   ├── machine-table.tsx
│   ├── supplier-form.tsx  │   ├── employee-form.tsx │   ├── machine-form.tsx
│   └── hooks/             │   └── hooks/            │   └── hooks/
├── adicionar/page.tsx     ├── adicionar/page.tsx   ├── adicionar/page.tsx
├── editar/[id]/page.tsx   ├── editar/[id]/page.tsx ├── editar/[id]/page.tsx
└── page.tsx               └── page.tsx             └── page.tsx
```

### **URLs Resultantes**

```
# Fornecedores
/fornecedores                           # Lista fornecedores
/fornecedores/adicionar                 # Criar fornecedor
/fornecedores/editar/[id]              # Editar fornecedor
/fornecedores/categorias               # Lista categorias
/fornecedores/categorias/adicionar     # Criar categoria
/fornecedores/categorias/editar/[id]   # Editar categoria

# Funcionários
/funcionarios                          # Lista funcionários
/funcionarios/adicionar                # Criar funcionário
/funcionarios/editar/[id]             # Editar funcionário
/funcionarios/departamentos           # Lista departamentos
/funcionarios/departamentos/adicionar # Criar departamento
/funcionarios/departamentos/editar/[id] # Editar departamento

# Máquinas
/maquinas                             # Lista máquinas
/maquinas/adicionar                   # Criar máquina
/maquinas/editar/[id]                # Editar máquina
/maquinas/tipos                      # Lista tipos
/maquinas/tipos/adicionar            # Criar tipo
/maquinas/tipos/editar/[id]         # Editar tipo
```

## **Comparação com Outras Abordagens**

### **❌ Abordagem Centralizada (Evitada)**

```
src/
├── components/
│   ├── suppliers/
│   │   ├── SupplierTable.tsx
│   │   ├── SupplierForm.tsx
│   │   └── SupplierStats.tsx
│   ├── employees/
│   │   ├── EmployeeTable.tsx
│   │   └── EmployeeForm.tsx
│   └── categories/
│       ├── CategoryTable.tsx
│       └── CategoryForm.tsx
└── app/
    ├── suppliers/page.tsx      # Import: ../../components/suppliers/SupplierTable
    └── employees/page.tsx      # Import: ../../components/employees/EmployeeTable
```

**Problemas da Abordagem Centralizada:**

- Imports longos e confusos
- Dificulta refatoração de recursos
- Mistura conceitos de diferentes domínios
- Dificulta descoberta de componentes
- Acoplamento desnecessário entre módulos
- Dificulta remoção/movimentação de features

### **✅ Abordagem Co-located (Adotada)**

```
app/
├── suppliers/
│   ├── _components/
│   │   ├── supplier-table.tsx
│   │   ├── supplier-form.tsx
│   │   └── supplier-stats.tsx
│   └── page.tsx               # Import: ./_components/supplier-table
└── employees/
    ├── _components/
    │   ├── employee-table.tsx
    │   └── employee-form.tsx
    └── page.tsx               # Import: ./_components/employee-table
```

**Vantagens da Abordagem Co-located:**

- Imports curtos e claros
- Refatoração mais fácil
- Coesão por domínio
- Descoberta natural de componentes
- Baixo acoplamento entre módulos
- Facilita remoção/movimentação de features

## **Implementação Prática**

### **Estrutura de Arquivos Detalhada**

```
fornecedores/
├── _components/
│   ├── supplier-data-table.tsx     # Tabela principal
│   ├── supplier-columns.tsx        # Definições de colunas
│   ├── supplier-form.tsx           # Formulário create/edit
│   ├── supplier-stats-cards.tsx    # Cards de estatísticas
│   ├── supplier-filters.tsx        # Componente de filtros
│   ├── hooks/
│   │   ├── use-suppliers.ts        # Hook principal de dados
│   │   ├── use-supplier-form.ts    # Hook para formulário
│   │   └── use-supplier-stats.ts   # Hook para estatísticas
│   ├── types/
│   │   └── supplier-types.ts       # Types específicos locais
│   └── utils/
│       ├── supplier-utils.ts       # Utilitários específicos
│       └── supplier-validations.ts # Validações específicas
├── (categorias)/                   # Sub-recurso
├── adicionar/page.tsx              # Página de criação
├── editar/[supplierId]/page.tsx    # Página de edição
└── page.tsx                        # Página principal (listagem)
```

### **Exemplo de Implementação**

```typescript
// fornecedores/_components/hooks/use-suppliers.ts
export function useSuppliers() {
  return useQuery({
    queryKey: ['suppliers'],
    queryFn: getSuppliers,
    staleTime: 5 * 60 * 1000,
  });
}

// fornecedores/_components/supplier-data-table.tsx
import { useSuppliers } from './hooks/use-suppliers';

export function SupplierDataTable() {
  const { data: suppliers, isLoading } = useSuppliers();

  if (isLoading) return <DataTableSkeleton />;

  return (
    <DataTable
      columns={supplierColumns}
      data={suppliers}
    />
  );
}

// fornecedores/page.tsx
import { SupplierDataTable } from './_components/supplier-data-table';
import { SupplierStatsCards } from './_components/supplier-stats-cards';

export default function SuppliersPage() {
  return (
    <div className="space-y-6">
      <SupplierStatsCards />
      <SupplierDataTable />
    </div>
  );
}
```

## **Migração e Refatoração**

### **Guia de Migração**

1. **Identificar Componentes Específicos**
   - Componentes usados apenas em um recurso
   - Hooks específicos de uma feature
   - Utilitários locais

2. **Criar Estrutura Co-located**

   ```bash
   mkdir -p app/resource/_components/hooks
   mkdir -p app/resource/_components/types
   mkdir -p app/resource/_components/utils
   ```

3. **Mover Componentes**
   - Mover arquivos para pasta `_components`
   - Atualizar imports relativos
   - Remover exports desnecessários

4. **Validar Funcionalidade**
   - Testar todas as páginas do recurso
   - Verificar builds e tipos
   - Confirmar navegação

### **Checklist de Refatoração**

- [ ] Componentes específicos identificados
- [ ] Estrutura `_components` criada
- [ ] Arquivos movidos e renomeados
- [ ] Imports atualizados
- [ ] Hooks co-located organizados
- [ ] Types específicos movidos
- [ ] Utilitários reorganizados
- [ ] Testes funcionando
- [ ] Build sem erros
- [ ] Performance mantida

## **Conclusão**

O padrão co-located components oferece uma abordagem organizada, escalável e mantível para estruturar componentes em aplicações Next.js. Ao manter componentes próximos ao seu uso, o projeto ganha em clareza, facilidade de manutenção e performance, criando uma base sólida para crescimento e evolução contínua.

## **Referências**

- **[02-ARCHITECTURE.md](../02-ARCHITECTURE.md)**: Visão geral da arquitetura
- **[15-COMPONENT-PATTERNS.md](../15-COMPONENT-PATTERNS.md)**: Implementações React e TanStack
- **Next.js App Router Documentation**: Estrutura de pastas e co-location
- **Domain-Driven Design**: Organização por domínio de negócio
