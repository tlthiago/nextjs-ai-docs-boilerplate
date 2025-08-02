# Query Performance Monitoring - Implementação Futura

## 🎯 **Visão Geral**

Estratégias para **monitoramento** e **otimização** de performance de queries SQL no **Avocado HP** quando o projeto crescer e demandar análise mais detalhada.

## 📊 **pg_stat_statements - Extensão PostgreSQL**

### **O que é:**

- **Extensão oficial** do PostgreSQL
- **Coleta estatísticas** detalhadas de todas as queries executadas
- **Identifica queries lentas** e padrões de uso
- **Fundamental** para otimização de performance

### **Quando Implementar:**

- ✅ **Volume alto** de queries (>1000/min)
- ✅ **Performance issues** reportadas pelos usuários
- ✅ **Necessidade** de otimização proativa
- ✅ **Ambiente de produção** estável

### **Como Implementar:**

#### **1. Configuração do PostgreSQL:**

```sql
-- Adicionar ao init-db.sql quando necessário
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Configurações de sistema
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET pg_stat_statements.max = 10000;
ALTER SYSTEM SET pg_stat_statements.track = 'all';
ALTER SYSTEM SET pg_stat_statements.track_utility = on;

-- Reload da configuração
SELECT pg_reload_conf();
```

#### **2. Queries Úteis para Análise:**

##### **Top 10 Queries Mais Lentas:**

```sql
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

##### **Queries Mais Executadas:**

```sql
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    (total_exec_time/calls) as avg_time_ms
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;
```

##### **Queries que Consomem Mais Tempo Total:**

```sql
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    (total_exec_time/sum(total_exec_time) OVER()) * 100 as percentage
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

#### **3. Reset de Estatísticas:**

```sql
-- Limpar estatísticas coletadas
SELECT pg_stat_statements_reset();
```

## 🔍 **Query Logging - Alternativa Simples**

### **Para Debugging Pontual:**

```sql
-- Habilitar logging temporário
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_duration = on;
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Apenas queries > 1s

SELECT pg_reload_conf();
```

### **Desabilitar Após Debug:**

```sql
ALTER SYSTEM SET log_statement = 'none';
ALTER SYSTEM SET log_duration = off;
ALTER SYSTEM SET log_min_duration_statement = -1;

SELECT pg_reload_conf();
```

## 📈 **Integração com Monitoramento**

### **Grafana Dashboard - Queries Performance:**

```yaml
# Métricas para coletar via Prometheus
metrics:
  - pg_stat_statements_total_exec_time
  - pg_stat_statements_calls
  - pg_stat_statements_mean_exec_time
  - pg_stat_statements_rows
```

### **Alertas Importantes:**

- **Query > 5s**: Alerta de performance crítica
- **Query > 1000 calls/min**: Possível N+1 problem
- **Total queries > 10k/min**: Limite de escala do PostgreSQL

## 🚀 **Implementação Gradual**

### **Fase 1: Monitoring Básico**

```typescript
// Middleware para logging de queries lentas
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient({
  log: [
    { emit: "event", level: "query" },
    { emit: "event", level: "error" },
    { emit: "event", level: "warn" },
  ],
});

prisma.$on("query", (e) => {
  if (e.duration > 1000) {
    // Queries > 1s
    console.log("Slow Query Detected:", {
      query: e.query,
      params: e.params,
      duration: `${e.duration}ms`,
      timestamp: e.timestamp,
    });
  }
});
```

### **Fase 2: Métricas Avançadas**

```typescript
// Coletar estatísticas via API
export async function getQueryStats() {
  const stats = await prisma.$queryRaw`
    SELECT 
      query,
      calls,
      total_exec_time,
      mean_exec_time,
      rows
    FROM pg_stat_statements 
    ORDER BY total_exec_time DESC 
    LIMIT 20
  `;

  return stats;
}

// Endpoint de monitoramento
// GET /api/admin/query-stats
```

### **Fase 3: Dashboard e Alertas**

- **Grafana Dashboard** com métricas de queries
- **Alertas automáticos** para queries lentas
- **Relatórios** de performance semanais
- **Sugestões automáticas** de otimização

## 🛠️ **Ferramentas Complementares**

### **pganalyze (SaaS)**

- **Análise automática** de performance
- **Sugestões** de otimização
- **Alertas inteligentes**
- **Custo**: ~$50/mês (quando necessário)

### **pg_stat_monitor (Percona)**

- **Alternativa** ao pg_stat_statements
- **Mais detalhes** sobre queries
- **Histogramas** de performance

### **EXPLAIN ANALYZE Automatizado**

```sql
-- Para queries específicas problemáticas
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM machinery WHERE status = 'ACTIVE';
```

## 📊 **Critérios para Implementação**

### **Indicadores que Justificam Implementação:**

1. **Reclamações** de lentidão dos usuários
2. **Tempo de resposta** > 2s em páginas principais
3. **CPU do banco** > 70% consistentemente
4. **Queries N+1** identificadas no código
5. **Crescimento** > 1000 usuários ativos

### **ROI da Implementação:**

- **Tempo de desenvolvimento**: ~8 horas
- **Benefício**: Identificação proativa de gargalos
- **Economia**: Evitar problemas de escala futuros
- **Experiência**: Usuários com aplicação mais rápida

## 🎯 **Estado Atual vs Futuro**

### **Situação Atual (Adequada):**

- ✅ **Prisma** gerencia UUIDs automaticamente
- ✅ **Queries otimizadas** pelo ORM
- ✅ **Volume baixo** de dados e usuários
- ✅ **Performance adequada** sem monitoramento avançado

### **Implementação Futura (Quando Necessário):**

- 🔄 **pg_stat_statements** para análise detalhada
- 🔄 **Query logging** para debugging específico
- 🔄 **Dashboard** de performance em Grafana
- 🔄 **Alertas automáticos** para queries problemáticas

## 📅 **Cronograma Sugerido**

### **Curto Prazo (Atual)**

- ✅ Manter simplicidade atual
- ✅ Monitorar performance manualmente
- ✅ Usar Prisma Studio para queries pontuais

### **Médio Prazo (6-12 meses)**

- 🔄 Implementar logging básico de queries lentas
- 🔄 Adicionar métricas ao endpoint `/api/metrics`
- 🔄 Monitorar crescimento de volume

### **Longo Prazo (1+ anos)**

- 🔄 pg_stat_statements completo
- 🔄 Dashboard dedicado de performance
- 🔄 Otimização proativa automatizada

---

**Status**: 📋 **Documentado para Implementação Futura**  
**Prioridade**: **Baixa** (implementar quando performance demandar)  
**Responsável**: Equipe de DevOps/Backend  
**Data**: Agosto 2025

### **Performance Monitoring Middleware**

```typescript
// lib/api/with-performance.ts
export function withPerformance(handler: ApiHandler): ApiHandler {
  return async (request: Request, context?: any) => {
    const startTime = Date.now();
    const requestId = crypto.randomUUID();

    try {
      const response = await handler(request, context);
      const responseTime = Date.now() - startTime;

      // Track successful request
      RequestTracker.getInstance().track({
        requestId,
        endpoint: new URL(request.url).pathname,
        method: request.method,
        statusCode: response.status,
        responseTime,
        timestamp: new Date(),
      });

      // Add performance headers
      response.headers.set("X-Response-Time", `${responseTime}ms`);
      response.headers.set("X-Request-ID", requestId);

      return response;
    } catch (error) {
      const responseTime = Date.now() - startTime;

      // Track failed request
      RequestTracker.getInstance().track({
        requestId,
        endpoint: new URL(request.url).pathname,
        method: request.method,
        statusCode: 500,
        responseTime,
        timestamp: new Date(),
      });

      throw error;
    }
  };
}
```