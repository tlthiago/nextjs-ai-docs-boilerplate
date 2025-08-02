# 🏗️ Project Architecture

## **Tech Stack**

### **Framework & Linguagem**

- **Framework**: Next.js 15 with App Router
- **Linguagem**: TypeScript (strict mode)
- **Runtime**: Node.js 18+

### **Banco de Dados**

- **Database**: PostgreSQL 17
- **ORM**: Prisma
- **Migrations**: Prisma Migrate
- **Ambiente Dev**: Docker container (PostgreSQL Alpine)

### **Autenticação & Autorização**

- **Auth Provider**: Better Auth
- **Session Storage**: PostgreSQL (não Redis)No 
- **Strategy**: Session-based cookies
- **Password**: Bcrypt hashing

### **UI & Styling**

- **Styling**: TailwindCSS 4
- **Components and Design System**: Shadcn UI (Radix UI primitives)
- **Icons**: Lucide React
- **Theme**: Dark/light mode (next-themes)
- **Forms**: React Hook Form + Zod

### **Estado & Fetching**

- **Server State**: Tanstack Query (React Query)
- **Client State**: React hooks nativos
- **Caching**: React Query + Next.js cache
- **Revalidation**: React Query

### **Email**

- **Provider**: Configurável via Nodemailer
- **Templates**: React Email components

### **Infraestrutura**

- **Deploy**: Consultar documentação específica
- **Monitoring**: Consultar documentação específica

### **Testing & Quality**

- **Testing Strategy**: Integration Tests Only (Jest + Testcontainers)
- **Rationale**: Skip unit tests, focus on real database testing for maximum ROI
- **Linting**: ESLint + Prettier
- **Git Hooks**: Husky + lint-staged
- **Commits**: Commitlint (conventional)

## **Estrutura de Pastas**

```
src/
├── app/                   # App Router (Next.js 15)
│   ├── (private)/         # Authenticated routes group - contain resources
│   │   ├── dashboard/     # Dashboard Page
│   │   └── resources/     # Resources Page (example: users, products, orders)
│   │   │   ├── (categories)/      # Sub-resource route group
│   │   │   │   ├── _components/   # Sub-resource specific components
│   │   │   │   │   ├── category-columns.tsx
│   │   │   │   │   ├── category-data-table.tsx
│   │   │   │   │   ├── category-form.tsx
│   │   │   │   │   └── category-stats-cards.tsx
│   │   │   │   ├── create/        # Create new sub-resource
│   │   │   │   │   └── page.tsx   # Create category form
│   │   │   │   ├── edit/          # Edit existing sub-resource
│   │   │   │   │   └── [categoryId]/
│   │   │   │   │       └── page.tsx # Edit category form
│   │   │   │   └── page.tsx       # Sub-resource main page (categories listing)
│   │   │   ├── _components/       # Resource-specific components (co-located)
│   │   │   │   ├── resource-columns.tsx
│   │   │   │   ├── resource-data-table.tsx
│   │   │   │   ├── resource-data-table-row-actions.tsx
│   │   │   │   ├── resource-form.tsx
│   │   │   │   └── resource-stats-cards.tsx
│   │   │   ├── create/            # Create new resource route
│   │   │   │   └── page.tsx       # Create form page
│   │   │   ├── edit/              # Edit existing resource route
│   │   │   │   └── [resourceId]/
│   │   │   │       └── page.tsx   # Edit form page
│   │   │   └── page.tsx           # Resource main page (listing)
│   ├── (public)/          # Public routes group
│   │   ├── login/         # Authentication pages
│   │   └── register/      # User registration
│   ├── api/               # API Routes
│   │   └── v1/            # API versioning
│   ├── globals.css        # Global styles
│   └── layout.tsx         # Root layout
├── components/            # Reusable React components (cross-domain)
│   ├── ui/               # Base components (Radix UI)
│   ├── navbar.tsx        # Main navigation
│   ├── sidebar.tsx       # Side menu
│   └── data-table/       # Generic table components
├── lib/                  # Utilities and configurations
│   ├── auth.ts           # Better Auth configuration
│   ├── prisma.ts         # Prisma client
│   ├── utils.ts          # Utility functions
│   ├── email/            # Email configuration
│   └── errors/           # Error handling
├── services/             # Service layer
│   ├── resources/        # Resource-related services (generic CRUD)
│   ├── users/            # User management services
│   ├── auth/             # Authentication services
│   └── common/           # Shared business logic
├── types/                # Global TypeScript types
├── hooks/                # Custom hooks (global)
└── generated/            # Generated code (Prisma Client)
    └── prisma/

__tests__/                # Tests (Jest + Testcontainers)
├── helpers/              # Test helpers
│   ├── factories/        # Factory functions for data
│   ├── testcontainers.ts # Testcontainers configuration
│   └── auth.ts           # Authentication helper
└── api/                  # API integration tests
    └── resources/        # Resource tests (generic patterns)

prisma/
├── schema.prisma         # Database schema
└── migrations/           # Migrations
```
