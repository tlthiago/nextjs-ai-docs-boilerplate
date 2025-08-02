# 📈 Avocado HP - Monitoramento

## **Estratégia de Monitoramento**

### **Visão Geral**

- **Monitoramento Centralizado**: Single Grafana + Prometheus + Loki stack
- **Métricas de Aplicação**: Cada app expõe endpoint `/api/metrics`
- **Agregação de Logs**: Logs estruturados coletados pelo Loki
- **Multi-Projeto**: Uma stack de monitoramento para todos os projetos do VPS
- **Dashboards**: Visão unificada de todas as aplicações e infraestrutura

### **Arquitetura de Monitoramento**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Prometheus    │    │    Grafana      │
│   /api/metrics  │───►│   (Scraping)    │───►│   (Dashboard)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         └─────────────►│      Loki       │◄─────────────┘
                        │   (Logs)        │
                        └─────────────────┘
```

## **Exposição de Métricas**

### **Endpoint Principal**

```typescript
// app/api/metrics/route.ts
import { NextResponse } from "next/server";
import {
  register,
  collectDefaultMetrics,
  Counter,
  Histogram,
  Gauge,
} from "prom-client";
import { prisma } from "@/lib/prisma";

// Collect default Node.js metrics
collectDefaultMetrics({
  prefix: "avocado_hp_",
  register,
});

// Custom application metrics
const httpRequestDuration = new Histogram({
  name: "avocado_hp_http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status_code"],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
});

const httpRequestTotal = new Counter({
  name: "avocado_hp_http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status_code"],
});

const databaseConnectionPool = new Gauge({
  name: "avocado_hp_database_connections",
  help: "Number of active database connections",
  labelNames: ["pool_name", "state"],
});

const activeUsers = new Gauge({
  name: "avocado_hp_active_users_total",
  help: "Number of currently active users",
});

const businessMetrics = {
  totalSuppliers: new Gauge({
    name: "avocado_hp_suppliers_total",
    help: "Total number of suppliers",
  }),

  totalEmployees: new Gauge({
    name: "avocado_hp_employees_total",
    help: "Total number of employees",
  }),

  totalMachineries: new Gauge({
    name: "avocado_hp_machineries_total",
    help: "Total number of machineries",
  }),
};

export async function GET() {
  // Update custom metrics before exposing
  await updateCustomMetrics();

  const metrics = await register.metrics();
  return new NextResponse(metrics, {
    headers: {
      "Content-Type": register.contentType,
    },
  });
}

async function updateCustomMetrics() {
  try {
    // Update database connection metrics
    const poolStats = await prisma.$queryRaw<
      Array<{ state: string; count: bigint }>
    >`
      SELECT state, count(*) as count 
      FROM pg_stat_activity 
      WHERE datname = current_database() 
      GROUP BY state
    `;

    // Reset gauge before setting new values
    databaseConnectionPool.reset();

    poolStats.forEach((stat) => {
      databaseConnectionPool.set(
        { pool_name: "main", state: stat.state || "unknown" },
        Number(stat.count),
      );
    });

    // Update active users (sessions from last 5 minutes)
    const activeUserCount = await prisma.session.count({
      where: {
        expiresAt: {
          gt: new Date(Date.now() - 5 * 60 * 1000), // 5 minutes ago
        },
      },
    });

    activeUsers.set(activeUserCount);

    // Update business metrics
    const [supplierCount, employeeCount, machineryCount] = await Promise.all([
      prisma.supplier.count({ where: { status: { not: "DELETED" } } }),
      prisma.employee.count({ where: { status: { not: "DELETED" } } }),
      prisma.machinery.count({ where: { status: { not: "DELETED" } } }),
    ]);

    businessMetrics.totalSuppliers.set(supplierCount);
    businessMetrics.totalEmployees.set(employeeCount);
    businessMetrics.totalMachineries.set(machineryCount);
  } catch (error) {
    console.error("Failed to update metrics:", error);
  }
}
```

### **Instrumentação Automática**

```typescript
// lib/monitoring-middleware.ts
import { NextRequest, NextResponse } from "next/server";
import { httpRequestDuration, httpRequestTotal } from "./metrics";
import { logger } from "./logger";

export function withMonitoring(
  handler: (request: NextRequest) => Promise<NextResponse>,
) {
  return async (request: NextRequest) => {
    const startTime = Date.now();
    const requestId = crypto.randomUUID();

    try {
      logger.info("Request started", {
        requestId,
        method: request.method,
        url: request.url,
        userAgent: request.headers.get("user-agent"),
      });

      const response = await handler(request);
      const duration = (Date.now() - startTime) / 1000;

      // Record metrics
      httpRequestDuration
        .labels(request.method, request.url, response.status.toString())
        .observe(duration);

      httpRequestTotal
        .labels(request.method, request.url, response.status.toString())
        .inc();

      logger.info("Request completed", {
        requestId,
        method: request.method,
        url: request.url,
        statusCode: response.status,
        duration: `${duration}s`,
      });

      return response;
    } catch (error) {
      const duration = (Date.now() - startTime) / 1000;

      httpRequestDuration
        .labels(request.method, request.url, "500")
        .observe(duration);

      httpRequestTotal.labels(request.method, request.url, "500").inc();

      logger.error("Request failed", error as Error, {
        requestId,
        method: request.method,
        url: request.url,
        duration: `${duration}s`,
      });

      throw error;
    }
  };
}
```

## **Logs Estruturados**

### **Logger Principal**

```typescript
// lib/logger.ts
interface LogContext {
  userId?: string;
  requestId?: string;
  action?: string;
  resource?: string;
  [key: string]: any;
}

export const logger = {
  info: (message: string, context?: LogContext) => {
    console.log(
      JSON.stringify({
        level: "info",
        message,
        timestamp: new Date().toISOString(),
        service: "avocado-hp",
        environment: process.env.NODE_ENV,
        version: process.env.npm_package_version || "1.0.0",
        ...context,
      }),
    );
  },

  error: (message: string, error?: Error, context?: LogContext) => {
    console.error(
      JSON.stringify({
        level: "error",
        message,
        error: {
          name: error?.name,
          message: error?.message,
          stack: error?.stack,
        },
        timestamp: new Date().toISOString(),
        service: "avocado-hp",
        environment: process.env.NODE_ENV,
        version: process.env.npm_package_version || "1.0.0",
        ...context,
      }),
    );
  },

  warn: (message: string, context?: LogContext) => {
    console.warn(
      JSON.stringify({
        level: "warn",
        message,
        timestamp: new Date().toISOString(),
        service: "avocado-hp",
        environment: process.env.NODE_ENV,
        version: process.env.npm_package_version || "1.0.0",
        ...context,
      }),
    );
  },

  debug: (message: string, context?: LogContext) => {
    if (
      process.env.NODE_ENV === "development" ||
      process.env.LOG_LEVEL === "debug"
    ) {
      console.debug(
        JSON.stringify({
          level: "debug",
          message,
          timestamp: new Date().toISOString(),
          service: "avocado-hp",
          environment: process.env.NODE_ENV,
          version: process.env.npm_package_version || "1.0.0",
          ...context,
        }),
      );
    }
  },
};
```

### **Uso em API Routes**

```typescript
// app/api/v1/suppliers/route.ts
import { withMonitoring } from "@/lib/monitoring-middleware";
import { logger } from "@/lib/logger";

async function GET(request: NextRequest) {
  const session = await auth.api.getSession({ headers: request.headers });

  logger.info("Fetching suppliers", {
    userId: session?.user?.id,
    action: "list_suppliers",
  });

  try {
    const suppliers = await prisma.supplier.findMany({
      where: { status: { not: "DELETED" } },
    });

    logger.info("Suppliers fetched successfully", {
      userId: session?.user?.id,
      action: "list_suppliers",
      count: suppliers.length,
    });

    return NextResponse.json({ data: suppliers });
  } catch (error) {
    logger.error("Failed to fetch suppliers", error as Error, {
      userId: session?.user?.id,
      action: "list_suppliers",
    });

    throw error;
  }
}

// Export wrapped handler
export const GET = withMonitoring(GET);
```

## **Alertas e Notificações**

### **Configuração de Alertas (Prometheus)**

```yaml
# prometheus-alerts.yml
groups:
  - name: avocado-hp-alerts
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: rate(avocado_hp_http_requests_total{status_code=~"5.."}[5m]) > 0.05
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors per second"

      # High response time
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(avocado_hp_http_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}s"

      # Database connection issues
      - alert: DatabaseConnectionHigh
        expr: avocado_hp_database_connections > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High database connection count"
          description: "Database has {{ $value }} active connections"

      # Memory usage high
      - alert: HighMemoryUsage
        expr: (process_resident_memory_bytes / (1024 * 1024)) > 800
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value }}MB"

      # Application down
      - alert: ApplicationDown
        expr: up{job="avocado-hp"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Application is down"
          description: "Avocado HP application is not responding"
```

### **Business Logic Alerts**

```typescript
// lib/business-alerts.ts
import { logger } from "./logger";

export class BusinessAlertService {
  static async checkSupplierThresholds() {
    const supplierCount = await prisma.supplier.count({
      where: { status: { not: "DELETED" } },
    });

    if (supplierCount < 5) {
      logger.warn("Low supplier count", {
        action: "business_alert",
        metric: "supplier_count",
        value: supplierCount,
        threshold: 5,
      });
    }
  }

  static async checkInactiveUsers() {
    const inactiveUsers = await prisma.user.count({
      where: {
        sessions: {
          none: {
            expiresAt: {
              gt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days
            },
          },
        },
      },
    });

    if (inactiveUsers > 10) {
      logger.warn("High inactive user count", {
        action: "business_alert",
        metric: "inactive_users",
        value: inactiveUsers,
        threshold: 10,
      });
    }
  }
}
```

## **Dashboard Configuration**

### **Grafana Dashboard JSON**

```json
{
  "dashboard": {
    "title": "Avocado HP - Application Dashboard",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(avocado_hp_http_requests_total[5m])",
            "legendFormat": "{{method}} {{route}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(avocado_hp_http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(avocado_hp_http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "50th percentile"
          }
        ]
      },
      {
        "title": "Active Users",
        "type": "singlestat",
        "targets": [
          {
            "expr": "avocado_hp_active_users_total",
            "legendFormat": "Active Users"
          }
        ]
      },
      {
        "title": "Business Metrics",
        "type": "table",
        "targets": [
          {
            "expr": "avocado_hp_suppliers_total",
            "legendFormat": "Suppliers"
          },
          {
            "expr": "avocado_hp_employees_total",
            "legendFormat": "Employees"
          },
          {
            "expr": "avocado_hp_machineries_total",
            "legendFormat": "Machineries"
          }
        ]
      },
      {
        "title": "Database Connections",
        "type": "graph",
        "targets": [
          {
            "expr": "avocado_hp_database_connections",
            "legendFormat": "{{state}}"
          }
        ]
      },
      {
        "title": "Error Rate by Route",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(avocado_hp_http_requests_total{status_code=~\"5..\"}[5m])",
            "legendFormat": "{{route}}"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

## **Performance Monitoring**

### **Core Web Vitals**

```typescript
// lib/web-vitals.ts
import { onCLS, onFID, onFCP, onLCP, onTTFB } from "web-vitals";

function sendToAnalytics(metric: any) {
  // Send to your analytics endpoint
  fetch("/api/analytics", {
    method: "POST",
    body: JSON.stringify(metric),
    headers: { "Content-Type": "application/json" },
  });
}

export function reportWebVitals() {
  onCLS(sendToAnalytics);
  onFID(sendToAnalytics);
  onFCP(sendToAnalytics);
  onLCP(sendToAnalytics);
  onTTFB(sendToAnalytics);
}
```

### **Database Query Monitoring**

```typescript
// lib/prisma-instrumentation.ts
import { PrismaClient } from "@prisma/client";
import { logger } from "./logger";

export const prisma = new PrismaClient({
  log: [
    { emit: "event", level: "query" },
    { emit: "event", level: "error" },
    { emit: "event", level: "warn" },
  ],
});

// Log slow queries
prisma.$on("query", (e) => {
  if (e.duration > 1000) {
    // Log queries slower than 1s
    logger.warn("Slow query detected", {
      query: e.query,
      params: e.params,
      duration: `${e.duration}ms`,
      timestamp: e.timestamp,
    });
  }
});

// Log database errors
prisma.$on("error", (e) => {
  logger.error("Database error", new Error(e.message), {
    target: e.target,
    timestamp: e.timestamp,
  });
});
```

## **Monitoramento de Recursos**

### **System Metrics**

```typescript
// lib/system-metrics.ts
import * as os from "os";

export function collectSystemMetrics() {
  return {
    memory: {
      total: os.totalmem(),
      free: os.freemem(),
      used: os.totalmem() - os.freemem(),
      usage: ((os.totalmem() - os.freemem()) / os.totalmem()) * 100,
    },
    cpu: {
      count: os.cpus().length,
      loadAverage: os.loadavg(),
      usage: process.cpuUsage(),
    },
    uptime: {
      system: os.uptime(),
      process: process.uptime(),
    },
  };
}
```

### **Container Labels para Descoberta**

```yaml
# docker-compose.yml
services:
  app:
    image: avocado-hp:latest
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=3000"
      - "prometheus.path=/api/metrics"
      - "prometheus.interval=30s"
      - "service.name=avocado-hp"
      - "service.version=1.0.0"
      - "service.environment=production"
```

## **Observabilidade Distribuída**

### **Request Tracing**

```typescript
// lib/tracing.ts
export function generateTraceId(): string {
  return crypto.randomUUID();
}

export function propagateTrace(request: NextRequest): string {
  const traceId = request.headers.get("x-trace-id") || generateTraceId();

  // Add to all outgoing requests
  return traceId;
}

// Usage in API routes
export async function GET(request: NextRequest) {
  const traceId = propagateTrace(request);

  logger.info("API request started", {
    traceId,
    endpoint: request.url,
    method: request.method,
  });

  // ... rest of the handler
}
```
## 📝 **Logging and Monitoring**

### **Logging Pattern**

```typescript
// Use structured console.log
console.log({
  level: "info",
  message: "Machinery created",
  userId: session.user.id,
  machineryId: machinery.id,
  timestamp: new Date().toISOString(),
});

console.error({
  level: "error",
  message: "Failed to create machinery",
  error: error.message,
  userId: session.user.id,
  timestamp: new Date().toISOString(),
});
```

## 📊 **API Observability**

### **Request Tracking**

```typescript
// lib/api/request-tracker.ts
interface RequestMetrics {
  requestId: string;
  endpoint: string;
  method: string;
  statusCode: number;
  responseTime: number;
  userId?: string;
  timestamp: Date;
}

export class RequestTracker {
  private static instance: RequestTracker;
  private metrics: RequestMetrics[] = [];

  static getInstance() {
    if (!RequestTracker.instance) {
      RequestTracker.instance = new RequestTracker();
    }
    return RequestTracker.instance;
  }

  track(metrics: RequestMetrics) {
    this.metrics.push(metrics);

    // Log for development
    if (process.env.NODE_ENV === "development") {
      console.log(
        `[API] ${metrics.method} ${metrics.endpoint} - ${metrics.statusCode} - ${metrics.responseTime}ms`,
      );
    }

    // Send to monitoring service in production
    if (process.env.NODE_ENV === "production") {
      this.sendToMonitoring(metrics);
    }
  }

  private async sendToMonitoring(metrics: RequestMetrics) {
    // Integration with monitoring services
    // e.g., DataDog, New Relic, CloudWatch
  }

  getMetrics(filter?: Partial<RequestMetrics>) {
    return this.metrics.filter((metric) => {
      if (!filter) return true;
      return Object.entries(filter).every(
        ([key, value]) => metric[key as keyof RequestMetrics] === value,
      );
    });
  }
}
```

### **Health Check Endpoints**

```typescript
// app/api/health/route.ts
export async function GET() {
  const healthStatus = {
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || "unknown",
    environment: process.env.NODE_ENV,
    uptime: process.uptime(),
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
    },
  };

  return NextResponse.json(healthStatus);
}
```

```typescript
// app/api/health/db/route.ts
export async function GET() {
  try {
    // Test database connection (implementation in DATA-PATTERNS)
    await prisma.$queryRaw`SELECT 1`;

    return NextResponse.json({
      status: "healthy",
      database: "connected",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: "unhealthy",
        database: "disconnected",
        error: "Database connection failed",
        timestamp: new Date().toISOString(),
      },
      { status: 503 },
    );
  }
}
```