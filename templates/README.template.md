# 📚 Avocado HP - Documentação

Documentação técnica completa para desenvolvimento com agentes de IA.

## 🚀 **Início Rápido para Agentes IA**

### **Leitura Obrigatória (ordem de prioridade):**

1. 🎯 [`01-OVERVIEW.md`](01-OVERVIEW.md) - O que é o projeto
2. 🏗️ [`02-ARCHITECTURE.md`](02-ARCHITECTURE.md) - Tech stack e estrutura
3. 💻 [`03-DEVELOPMENT.md`](03-DEVELOPMENT.md) - Como desenvolver
4. 🔌 [`06-API-PATTERNS.md`](06-API-PATTERNS.md) - Padrões de API
5. 🧩 [`04-COMPONENT-PATTERNS.md`](04-COMPONENT-PATTERNS.md) - Padrões de componentes
6. 🧪 [`09-TESTING-STRATEGY.md`](09-TESTING-STRATEGY.md) - Estratégia de testes

### **Documentação Complementar:**

- 📊 [`07-DATA-PATTERNS.md`](07-DATA-PATTERNS.md) - Padrões de dados e soft delete
- 🔐 [`10-AUTHENTICATION.md`](10-AUTHENTICATION.md) - Auth e segurança
- 🚀 [`11-DEPLOYMENT.md`](11-DEPLOYMENT.md) - Deploy e infraestrutura
- 📈 [`10-MONITORING.md`](10-MONITORING.md) - Monitoramento e logs
- 🎨 [`11-DESIGN-SYSTEM.md`](11-DESIGN-SYSTEM.md) - Design system e cores
- 🏢 [`12-BUSINESS-DOMAIN.md`](12-BUSINESS-DOMAIN.md) - Entidades e relacionamentos
- ⚠️ [`08-ERROR-HANDLING.md`](08-ERROR-HANDLING.md) - Tratamento de erros
- 📚 [`14-API-DOCUMENTATION.md`](14-API-DOCUMENTATION.md) - Documentação da API

### **Configuração e DevOps:**

- 🐳 [`DOCKER-COMPOSE-DECISIONS.md`](DOCKER-COMPOSE-DECISIONS.md) - Decisões Docker
- 🔄 [`CICD-PIPELINES.md`](CICD-PIPELINES.md) - CI/CD completo
- 🔑 [`GITHUB-SECRETS-SETUP.md`](GITHUB-SECRETS-SETUP.md) - Secrets do GitHub
- 📊 [`GLOBAL-MONITORING.md`](GLOBAL-MONITORING.md) - Monitoring VPS

### **Roadmap e Futuro:**

- 🔮 [`FUTURE-ENHANCEMENTS.md`](FUTURE-ENHANCEMENTS.md) - Melhorias futuras
- 📈 [`QUERY-MONITORING-FUTURE.md`](QUERY-MONITORING-FUTURE.md) - Monitoring avançado

## 🤖 **Como Usar com Agentes IA**

```
"Baseando-se na documentação em docs/, crie [funcionalidade]
seguindo os padrões estabelecidos. Consulte especialmente:
- 06-API-PATTERNS.md para endpoints
- 04-COMPONENT-PATTERNS.md para UI
- 09-TESTING-STRATEGY.md para testes"
```

## 📝 **Template para Novas Features**

Ao solicitar uma nova feature para agentes IA, use este template:

```
Contexto: docs/README.md + docs/06-API-PATTERNS.md
Criar: [Recurso] completo
Incluir: CRUD + Validações + Testes + Componentes
Seguir: Padrões estabelecidos na documentação
```

## 🗺️ **Mapa da Documentação**

```
📚 Avocado HP Documentation
│
├── 🎯 INÍCIO RÁPIDO
│   ├── README.md ................................. Índice geral
│   ├── AI-CONTEXT.md ............................. Guia para agentes IA
│   └── 01-OVERVIEW.md ............................ Visão geral do projeto
│
├── 🏗️ ARQUITETURA
│   ├── 02-ARCHITECTURE.md ........................ Tech stack e estrutura
│   ├── 07-DATA-PATTERNS.md ....................... Padrões de dados
│   └── 12-BUSINESS-DOMAIN.md ..................... Entidades do negócio
│
├── 💻 DESENVOLVIMENTO
│   ├── 03-DEVELOPMENT.md ......................... Setup local
│   ├── 06-API-PATTERNS.md ........................ Padrões de API
│   ├── 04-COMPONENT-PATTERNS.md .................. Padrões de componentes
│   └── 09-TESTING-STRATEGY.md .................... Estratégia de testes
│
├── 🚀 DEPLOY & INFRA
│   ├── 11-DEPLOYMENT.md .......................... Deploy e infraestrutura
│   ├── 10-MONITORING.md .......................... Monitoramento
│   ├── DOCKER-COMPOSE-DECISIONS.md ............... Decisões Docker
│   └── CICD-PIPELINES.md ......................... CI/CD completo
│
├── 🔐 SEGURANÇA
│   ├── 10-AUTHENTICATION.md ...................... Auth e segurança
│   └── GITHUB-SECRETS-SETUP.md ................... Secrets do GitHub
│
├── 🎨 DESIGN
│   ├── 11-DESIGN-SYSTEM.md ....................... Design system
│   └── (rotas definidas em 02-ARCHITECTURE.md)
│
└── 🔮 FUTURO
    ├── FUTURE-ENHANCEMENTS.md .................... Roadmap
    ├── QUERY-MONITORING-FUTURE.md ................ Monitoring avançado
    └── GLOBAL-MONITORING.md ...................... Monitoring VPS
```

## 🎯 **Pontos de Entrada por Contexto**

### **"Quero criar uma API"**

→ [`06-API-PATTERNS.md`](06-API-PATTERNS.md) + [`09-TESTING-STRATEGY.md`](09-TESTING-STRATEGY.md)

### **"Quero criar um componente"**

→ [`04-COMPONENT-PATTERNS.md`](04-COMPONENT-PATTERNS.md) + [`11-DESIGN-SYSTEM.md`](11-DESIGN-SYSTEM.md)

### **"Quero entender o projeto"**

→ [`README.md`](README.md) + [`01-OVERVIEW.md`](01-OVERVIEW.md) + [`02-ARCHITECTURE.md`](02-ARCHITECTURE.md)

### **"Quero configurar ambiente"**

→ [`03-DEVELOPMENT.md`](03-DEVELOPMENT.md) + [`DOCKER-COMPOSE-DECISIONS.md`](DOCKER-COMPOSE-DECISIONS.md)
