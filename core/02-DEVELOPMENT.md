# 💻 Development Environment Setup

## **🎯 Overview**

This guide sets up a **production-like development environment** for Next.js enterprise applications. The setup prioritizes **developer productivity**, **AI agent compatibility**, and **consistency across team members**.

> 💡 **Philosophy**: Every developer should have an identical environment that works immediately, with zero configuration drift.

---

## 🔧 **Prerequisites**

### **System Requirements**

```bash
# Required versions
Node.js >= 20.0.0
npm >= 10.0.0 (or yarn >= 4.0.0)
Docker >= 24.0.0
Docker Compose >= 2.0.0
Git >= 2.40.0

# Verify your setup
node --version
npm --version
docker --version
docker compose version
```

### **Recommended Tools**

```bash
# Database GUI (optional)
- TablePlus, DBeaver, or pgAdmin

# VS Code Extensions (recommended)
- Prisma
- TypeScript Importer
- Tailwind CSS IntelliSense
- ESLint
- Prettier
```

---

## ⚡ **Quick Start**

### **1. Project Setup**

```bash
# Clone your repository
git clone <your-repo-url>
cd <your-project-name>

# Install dependencies
npm install

# Copy environment template
cp .env.example .env.local

# Start development environment
npm run dev
```

> ✅ **Expected Result**: Development server running on `http://localhost:3000` with database ready

### **2. Verify Setup**

```bash
# Test database connection
npm run db:status

# Run a quick test
npm run test:quick

# Check code quality
npm run lint:check
```

---

## 🐳 **Docker Development Environment**

### **docker-compose.dev.yml**

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:17-alpine
    container_name: ${PROJECT_NAME:-app}-dev-db
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ${PROJECT_NAME:-app}_dev
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Optional: Redis for caching (uncomment if needed)
  # redis:
  #   image: redis:7-alpine
  #   container_name: ${PROJECT_NAME:-app}-dev-redis
  #   ports:
  #     - "6379:6379"

volumes:
  postgres_dev_data:
```

### **Docker Commands**

```bash
# Start development services
docker compose -f docker-compose.dev.yml up -d

# Stop services
docker compose -f docker-compose.dev.yml down

# Reset database (destroys data!)
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml up -d

# View logs
docker compose -f docker-compose.dev.yml logs -f postgres
```

---

## 📋 **Environment Variables**

### **.env.local Template**

```env
# =============================================
# DATABASE CONFIGURATION
# =============================================
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/${PROJECT_NAME}_dev"

# =============================================
# AUTHENTICATION (Better Auth)
# =============================================
BETTER_AUTH_SECRET="your-super-secret-32-character-key-here"
BETTER_AUTH_URL="http://localhost:3000"

# =============================================
# NEXT.JS CONFIGURATION
# =============================================
NODE_ENV="development"
NEXT_PUBLIC_APP_URL="http://localhost:3000"

# =============================================
# EMAIL SERVICE (Development)
# =============================================
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER="your-email@gmail.com"
SMTP_PASSWORD="your-app-password"
SMTP_FROM="Your App <noreply@yourapp.com>"
```

### **Environment Setup**

```bash
# Generate a secure secret for Better Auth
openssl rand -base64 32

# Test environment variables
npm run env:check

# Validate required variables
npm run env:validate
```

---

## 🚀 **Development Scripts**

### **Package.json Scripts Template**

```json
{
  "scripts": {
    // ===========================================
    // DEVELOPMENT
    // ===========================================
    "dev": "npm run services:up && npm run db:ready && next dev --turbopack",
    "dev:clean": "npm run clean && npm run dev",
    "build": "prisma generate && next build",
    "start": "next start",
    "clean": "rm -rf .next && rm -rf node_modules/.cache",

    // ===========================================
    // DOCKER SERVICES
    // ===========================================
    "services:up": "docker compose -f docker-compose.dev.yml up -d",
    "services:down": "docker compose -f docker-compose.dev.yml down",
    "services:restart": "npm run services:down && npm run services:up",
    "services:reset": "docker compose -f docker-compose.dev.yml down -v && npm run services:up",
    "services:logs": "docker compose -f docker-compose.dev.yml logs -f",

    // ===========================================
    // DATABASE OPERATIONS
    // ===========================================
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate dev",
    "db:migrate:reset": "prisma migrate reset --force",
    "db:seed": "tsx prisma/seed.ts",
    "db:studio": "prisma studio",
    "db:ready": "wait-port 5432 && prisma generate && prisma db push",
    "db:status": "prisma migrate status",

    // ===========================================
    // TESTING
    // ===========================================
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:integration": "jest --config jest.integration.config.ts --runInBand",
    "test:quick": "jest --passWithNoTests --silent --noStackTrace",
    "test:all": "npm run test:quick && npm run test:integration",

    // ===========================================
    // CODE QUALITY
    // ===========================================
    "type:check": "tsc --noEmit",
    "lint": "next lint",
    "lint:fix": "next lint --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "quality:check": "npm run type:check && npm run lint && npm run format:check",
    "quality:fix": "npm run lint:fix && npm run format",

    // ===========================================
    // UTILITIES
    // ===========================================
    "env:check": "tsx scripts/check-env.ts",
    "env:validate": "tsx scripts/validate-env.ts",
    "setup": "npm install && npm run services:up && npm run db:ready && npm run db:seed",

    // ===========================================
    // GIT & COMMITS
    // ===========================================
    "commit": "cz"
  }
}
```

### **Daily Development Workflow**

```bash
# Morning startup (all-in-one)
npm run dev

# Or step-by-step
npm run services:up    # Start Docker services
npm run db:ready       # Wait for DB and sync schema
npm run dev           # Start Next.js dev server

# In separate terminals
npm run test:watch    # Continuous testing
npm run db:studio     # Database GUI

# Before committing
npm run quality:check # Type check + lint + format
npm run test:all      # Run all tests
```

---

## 🗄️ **Database Development**

### **Prisma Workflow**

```bash
# Create a new migration
npx prisma migrate dev --name "add-user-roles"

# Generate Prisma client after schema changes
npx prisma generate

# Reset database to clean state (development only!)
npx prisma migrate reset --force

# Apply existing migrations to database
npx prisma migrate deploy

# Open database GUI
npx prisma studio

# Prototype schema changes (no migration)
npx prisma db push
```

### **Database Seeding**

```typescript
// prisma/seed.ts - Example seed script
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  // Create admin user
  const admin = await prisma.user.upsert({
    where: { email: "admin@example.com" },
    update: {},
    create: {
      email: "admin@example.com",
      name: "Admin User",
      role: "admin",
    },
  });

  // Seed sample data
  console.log("Seeded:", admin);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

---

## 🧪 **Testing in Development**

### **Test Categories**

```bash
# Unit tests (components, utilities)
npm run test

# Integration tests (API, database)
npm run test:integration

# Watch mode for active development
npm run test:watch

# Coverage report
npm run test:coverage
```

### **Test Database Setup**

```bash
# Automatically handled by Testcontainers
# Each test suite gets isolated PostgreSQL container
# No manual database setup required
```

---

## 📏 **Code Quality Standards**

### **TypeScript Configuration**

```json
// tsconfig.json key settings
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

### **ESLint + Prettier**

```bash
# Check code quality
npm run quality:check

# Auto-fix issues
npm run quality:fix

# Pre-commit hook (automatically runs)
# - Type checking
# - ESLint
# - Prettier formatting
# - Test suite
```

### **Naming Conventions**

```typescript
// Files and folders
kebab-case: user-profile.tsx
kebab-case: create-user.ts

// React components
kebab-case: user-profile.tsx, create-user-form.tsx

// Functions and variables
camelCase: createUser, userProfile

// Constants
UPPER_SNAKE_CASE: API_BASE_URL, MAX_RETRIES

// Database tables/models
snake_case: user_profiles, order_items
```

---

## 🔍 **Debugging & Troubleshooting**

### **Common Issues & Solutions**

#### **🐛 Port Already in Use**

```bash
# Find process using port 3000
lsof -ti:3000

# Kill process
kill -9 $(lsof -ti:3000)

# Or use different port
npm run dev -- -p 3001
```

#### **🐛 Database Connection Issues**

```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Restart database service
npm run services:restart

# Check database logs
npm run services:logs postgres

# Test connection manually
psql "postgresql://postgres:postgres@localhost:5432/yourapp_dev"
```

#### **🐛 Prisma Client Issues**

```bash
# Regenerate Prisma client
npx prisma generate

# Clear Next.js cache
rm -rf .next

# Reset schema to database
npx prisma db push

# Complete reset (nuclear option)
npx prisma migrate reset --force
```

#### **🐛 Docker Problems**

```bash
# Free up disk space
docker system prune -f

# Rebuild containers
docker compose -f docker-compose.dev.yml build --no-cache

# Check Docker resources
docker system df
```

#### **🐛 Node/NPM Issues**

```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Check Node version
node --version  # Should be >= 20.0.0
```

### **Performance Debugging**

```bash
# Next.js build analysis
npm run build -- --analyze

# Check bundle size
npm run build && npx @next/bundle-analyzer

# Monitor memory usage
node --inspect npm run dev
```

---

## 💡 **Pro Tips for Productivity**

### **Development Speed**

```bash
# Use Turbopack for faster builds
npm run dev  # Already configured with --turbopack

# Parallel commands with concurrently
npm install -D concurrently
# Then run: npx concurrently "npm run dev" "npm run test:watch"

# Database GUI shortcuts
npm run db:studio  # Prisma Studio
# Or use TablePlus, DBeaver, etc.
```

### **VS Code Configuration**

```json
// .vscode/settings.json
{
  "typescript.preferences.importModuleSpecifier": "relative",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "files.exclude": {
    "**/.next": true,
    "**/node_modules": true
  }
}
```

### **Git Workflow Integration**

```bash
# Install conventional commit tools
npm install -D @commitlint/config-conventional commitlint husky commitizen cz-conventional-changelog

# Setup commitizen (in package.json)
{
  "config": {
    "commitizen": {
      "path": "./node_modules/cz-conventional-changelog"
    }
  }
}

# Use conventional commits
npm run commit  # Interactive commit with commitizen

# Pre-commit hooks automatically run:
# - Type checking
# - Linting
# - Prettier formatting
# - Tests

# Skip hooks in emergency (not recommended)
git commit --no-verify -m "emergency fix"
```

### **AI Agent Optimization**

```bash
# When working with AI agents, use these patterns:

# 1. Always include context in prompts
"Based on the patterns in 02-DEVELOPMENT.md, set up..."

# 2. Reference specific scripts
"Run npm run dev as shown in the development workflow"

# 3. Use the troubleshooting section
"If you encounter port issues, follow the debugging guide"
```

---

## 🔄 **Maintenance Tasks**

### **Weekly**

```bash
# Update dependencies
npm outdated
npm update

# Clean up Docker
docker system prune -f

# Check security
npm audit
npm audit fix
```

### **Monthly**

```bash
# Update major dependencies
npx npm-check-updates
npx npm-check-updates -u

# Review and update Node.js version
node --version  # Check for LTS updates
```

---

## 📚 **Additional Resources**

- **[Next.js Development Docs](https://nextjs.org/docs)**
- **[Prisma Documentation](https://www.prisma.io/docs)**
- **[Docker Compose Reference](https://docs.docker.com/compose/)**
- **[TypeScript Handbook](https://www.typescriptlang.org/docs/)**

---

**🚀 Ready to start developing? Run `npm run dev` and you're all set!**
