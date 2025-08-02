# 🚀 Deployment & Production Patterns

## **Overview**

This project uses **Docker** containerization with **CI/CD pipelines** for reliable production deployments, supporting multiple hosting platforms and database providers.

> 💡 **Philosophy**: Infrastructure as Code with automated deployments, monitoring, and rollback capabilities.

---

## 🐳 **Docker Configuration**

### **Production Dockerfile**

```dockerfile
# Dockerfile
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set environment variables for build
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_ENV production

# Generate Prisma client
RUN npx prisma generate

# Build the application
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

### **Development Docker Compose**

```yaml
# docker-compose.dev.yml
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://postgres:password@db:5432/app_dev
    volumes:
      - .:/app
      - /app/node_modules
    depends_on:
      - db
    command: npm run dev

  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: app_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data

volumes:
  postgres_dev_data:
```

### **Production Docker Compose**

```yaml
# docker-compose.prod.yml
version: "3.8"

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
      - NEXTAUTH_URL=${NEXTAUTH_URL}
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_prod_data:/var/lib/postgresql/data
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_prod_data:
```

---

## ⚙️ **CI/CD Pipeline**

### **GitHub Actions Workflow**

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: "20"
  DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Generate Prisma client
        run: npx prisma generate

      - name: Run database migrations
        run: npx prisma migrate deploy

      - name: Run tests
        run: npm run test

      - name: Run E2E tests
        run: npm run test:e2e

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Generate Prisma client
        run: npx prisma generate

      - name: Build application
        run: npm run build

      - name: Build Docker image
        run: docker build -t ${{ secrets.DOCKER_REGISTRY }}/app:${{ github.sha }} .

      - name: Login to Docker registry
        run: echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin ${{ secrets.DOCKER_REGISTRY }}

      - name: Push Docker image
        run: docker push ${{ secrets.DOCKER_REGISTRY }}/app:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Deploy to production
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.PRODUCTION_USER }}
          key: ${{ secrets.PRODUCTION_SSH_KEY }}
          script: |
            cd /opt/app
            docker pull ${{ secrets.DOCKER_REGISTRY }}/app:${{ github.sha }}
            docker-compose down
            docker-compose up -d
            docker system prune -f
```

### **Health Check Endpoint**

```typescript
// app/api/health/route.ts
import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(req: NextRequest) {
  try {
    // Check database connection
    await prisma.$queryRaw`SELECT 1`;

    // Check other critical services
    const checks = {
      database: "healthy",
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || "unknown",
      uptime: process.uptime(),
    };

    return Response.json(checks, { status: 200 });
  } catch (error) {
    return Response.json(
      {
        status: "unhealthy",
        error: error.message,
        timestamp: new Date().toISOString(),
      },
      { status: 503 }
    );
  }
}
```

---

## 🌐 **Platform-Specific Deployments**

### **Vercel Deployment**

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "installCommand": "npm ci",
  "framework": "nextjs",
  "functions": {
    "app/api/**": {
      "maxDuration": 30
    }
  },
  "env": {
    "DATABASE_URL": "@database-url",
    "NEXTAUTH_SECRET": "@nextauth-secret",
    "NEXTAUTH_URL": "@nextauth-url"
  },
  "build": {
    "env": {
      "NEXT_TELEMETRY_DISABLED": "1"
    }
  }
}
```

### **Railway Deployment**

```toml
# railway.toml
[build]
builder = "nixpacks"

[deploy]
healthcheckPath = "/api/health"
healthcheckTimeout = 100
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 10

[[services]]
name = "app"

[services.variables]
NODE_ENV = "production"
PORT = { default = 3000 }

[[services]]
name = "database"
source = "postgresql"

[services.variables]
POSTGRES_DB = "app"
```

### **DigitalOcean App Platform**

```yaml
# .do/app.yaml
name: nextjs-app
services:
  - name: web
    source_dir: /
    github:
      repo: your-username/your-repo
      branch: main
      deploy_on_push: true
    build_command: npm run build
    run_command: npm start
    environment_slug: node-js
    instance_count: 1
    instance_size_slug: basic-xxs
    env:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        type: SECRET
      - key: NEXTAUTH_SECRET
        type: SECRET
databases:
  - name: db
    engine: PG
    version: "15"
    production: true
```

---

## 📊 **Monitoring & Observability**

### **Application Monitoring**

```typescript
// lib/monitoring.ts
export interface MetricEvent {
  name: string;
  value: number;
  tags?: Record<string, string>;
  timestamp?: Date;
}

export class MonitoringService {
  private events: MetricEvent[] = [];

  track(event: MetricEvent) {
    this.events.push({
      ...event,
      timestamp: event.timestamp || new Date(),
    });

    // Send to monitoring service (Datadog, New Relic, etc.)
    this.sendToMonitoring(event);
  }

  trackHttpRequest(
    method: string,
    path: string,
    statusCode: number,
    duration: number
  ) {
    this.track({
      name: "http_request",
      value: duration,
      tags: {
        method,
        path,
        status_code: statusCode.toString(),
      },
    });
  }

  trackDatabaseQuery(query: string, duration: number) {
    this.track({
      name: "database_query",
      value: duration,
      tags: {
        query_type: this.getQueryType(query),
      },
    });
  }

  private sendToMonitoring(event: MetricEvent) {
    // Implementation depends on your monitoring provider
    if (process.env.NODE_ENV === "production") {
      console.log("Metric:", event);
    }
  }

  private getQueryType(query: string): string {
    const normalized = query.toLowerCase().trim();
    if (normalized.startsWith("select")) return "select";
    if (normalized.startsWith("insert")) return "insert";
    if (normalized.startsWith("update")) return "update";
    if (normalized.startsWith("delete")) return "delete";
    return "other";
  }
}

export const monitoring = new MonitoringService();
```

### **Error Tracking**

```typescript
// lib/error-tracking.ts
export interface ErrorContext {
  userId?: string;
  userAgent?: string;
  url?: string;
  timestamp: Date;
  environment: string;
  version?: string;
  tags?: Record<string, string>;
}

export class ErrorTracker {
  trackError(error: Error, context: Partial<ErrorContext> = {}) {
    const errorReport = {
      message: error.message,
      stack: error.stack,
      name: error.name,
      context: {
        timestamp: new Date(),
        environment: process.env.NODE_ENV || "unknown",
        version: process.env.APP_VERSION || "unknown",
        ...context,
      },
    };

    // Send to error tracking service (Sentry, Bugsnag, etc.)
    this.sendToErrorService(errorReport);
  }

  trackApiError(error: Error, request: Request, userId?: string) {
    this.trackError(error, {
      url: request.url,
      userAgent: request.headers.get("user-agent") || undefined,
      userId,
      tags: {
        type: "api_error",
      },
    });
  }

  private sendToErrorService(errorReport: any) {
    if (process.env.NODE_ENV === "production") {
      // Integration with error tracking service
      console.error("Error Report:", errorReport);
    }
  }
}

export const errorTracker = new ErrorTracker();
```

---

## 🔧 **Environment Configuration**

### **Environment Variables Template**

```bash
# .env.example
# Database
DATABASE_URL="postgresql://username:password@localhost:5432/database"

# Authentication
BETTER_AUTH_SECRET="your-super-secret-key-here"
BETTER_AUTH_URL="http://localhost:3000"

# Email
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASSWORD="your-app-password"
SMTP_FROM="Your App <noreply@yourapp.com>"

# External APIs
NEXT_PUBLIC_APP_URL="http://localhost:3000"

# Monitoring (Optional)
SENTRY_DSN=""
DATADOG_API_KEY=""

# Feature Flags (Optional)
ENABLE_ANALYTICS=false
ENABLE_CACHE=true
```

### **Configuration Validation**

```typescript
// lib/config.ts
import { z } from "zod";

const configSchema = z.object({
  // Database
  DATABASE_URL: z.string().url(),

  // Authentication
  BETTER_AUTH_SECRET: z.string().min(32),
  BETTER_AUTH_URL: z.string().url(),

  // Email
  SMTP_HOST: z.string(),
  SMTP_PORT: z.coerce.number(),
  SMTP_USER: z.string().email(),
  SMTP_PASSWORD: z.string(),
  SMTP_FROM: z.string().email(),

  // Application
  NODE_ENV: z.enum(["development", "production", "test"]),
  PORT: z.coerce.number().default(3000),

  // Optional
  SENTRY_DSN: z.string().optional(),
  ENABLE_ANALYTICS: z.coerce.boolean().default(false),
});

export type Config = z.infer<typeof configSchema>;

export function validateConfig(): Config {
  try {
    return configSchema.parse(process.env);
  } catch (error) {
    console.error("❌ Invalid environment configuration:");
    console.error(error.issues);
    process.exit(1);
  }
}

export const config = validateConfig();
```

---

## 🔄 **Database Migration Strategy**

### **Migration Scripts**

```bash
#!/bin/bash
# scripts/migrate.sh

set -e

echo "🚀 Starting database migration..."

# Backup database (production only)
if [ "$NODE_ENV" = "production" ]; then
  echo "📦 Creating database backup..."
  pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
fi

# Run migrations
echo "🔄 Running Prisma migrations..."
npx prisma migrate deploy

# Seed data if needed
if [ "$SEED_DATABASE" = "true" ]; then
  echo "🌱 Seeding database..."
  npx prisma db seed
fi

echo "✅ Migration completed successfully!"
```

### **Rollback Strategy**

```bash
#!/bin/bash
# scripts/rollback.sh

set -e

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
  echo "❌ Usage: ./rollback.sh <backup_file>"
  exit 1
fi

echo "⚠️  Rolling back database to $BACKUP_FILE"
echo "This will overwrite all current data!"
read -p "Are you sure? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Restore from backup
  psql $DATABASE_URL < $BACKUP_FILE
  echo "✅ Database rollback completed"
else
  echo "❌ Rollback cancelled"
fi
```

---

## 🧪 **Production Testing**

### **Smoke Tests**

```typescript
// __tests__/smoke/production.test.ts
import { describe, it, expect } from "@jest/globals";

const BASE_URL = process.env.PRODUCTION_URL || "http://localhost:3000";

describe("Production Smoke Tests", () => {
  it("should serve the homepage", async () => {
    const response = await fetch(BASE_URL);
    expect(response.status).toBe(200);

    const html = await response.text();
    expect(html).toContain("<!DOCTYPE html>");
  });

  it("should respond to health check", async () => {
    const response = await fetch(`${BASE_URL}/api/health`);
    expect(response.status).toBe(200);

    const health = await response.json();
    expect(health.database).toBe("healthy");
  });

  it("should handle API authentication", async () => {
    const response = await fetch(`${BASE_URL}/api/protected`);
    expect(response.status).toBe(401);
  });

  it("should serve static assets", async () => {
    const response = await fetch(`${BASE_URL}/favicon.ico`);
    expect(response.status).toBe(200);
  });
});
```

### **Load Testing**

```javascript
// scripts/load-test.js
import http from "k6/http";
import { check, sleep } from "k6";

export let options = {
  stages: [
    { duration: "2m", target: 10 }, // Ramp up
    { duration: "5m", target: 10 }, // Stay at 10 users
    { duration: "2m", target: 20 }, // Ramp up to 20 users
    { duration: "5m", target: 20 }, // Stay at 20 users
    { duration: "2m", target: 0 }, // Ramp down
  ],
};

export default function () {
  // Test homepage
  let response = http.get("http://localhost:3000");
  check(response, {
    "status is 200": (r) => r.status === 200,
    "response time < 500ms": (r) => r.timings.duration < 500,
  });

  // Test API health
  response = http.get("http://localhost:3000/api/health");
  check(response, {
    "health check passes": (r) => r.status === 200,
    "database is healthy": (r) => JSON.parse(r.body).database === "healthy",
  });

  sleep(1);
}
```

---

## 📋 **Best Practices**

### **✅ Do:**

- Use multi-stage Docker builds for smaller images
- Implement health checks for all services
- Set up automated backups for production databases
- Use environment-specific configuration files
- Monitor application performance and errors
- Implement graceful shutdown handling
- Use HTTPS in production with proper certificates
- Set up log aggregation and monitoring

### **❌ Don't:**

- Store secrets in Docker images or Git
- Deploy without running tests first
- Skip database migration testing
- Use development dependencies in production
- Ignore monitoring and alerting
- Deploy manually to production
- Forget to set up rollback procedures
- Skip security headers and configurations

---

## 🔗 **Integration with Other Patterns**

- **API Patterns**: Health checks and monitoring endpoints
- **Error Handling**: Centralized error tracking and reporting
- **Testing**: Automated testing in CI/CD pipeline
- **Authentication**: Session management in production
- **Email**: SMTP configuration for production

This deployment strategy provides reliable, scalable, and monitorable production deployments while maintaining developer productivity and AI agent compatibility.
