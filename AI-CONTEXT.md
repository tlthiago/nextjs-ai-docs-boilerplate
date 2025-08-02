# 🤖 AI Agent Development Context

## **Project Overview**

This repository is a **documentation boilerplate** for Next.js enterprise applications. It is **NOT a runnable Next.js project** - it's a collection of markdown files, templates, and patterns that developers copy to their actual projects.

### **Repository Purpose**

- Provide production-ready documentation templates
- Optimize documentation structure for AI agent understanding
- Create consistent patterns across Next.js enterprise projects
- Enable rapid development with AI assistance

### **GitHub Repository**
- **Repository**: `git@github.com:tlthiago/nextjs-ai-docs-boilerplate.git`
- **Branch**: `main` (all development happens here)
- **Commit Policy**: Every completed task must be committed and pushed
- **Commit Format**: Use conventional commits with clear descriptions

---

## 🎯 **Development Mission**

Create **universally applicable documentation patterns** that:

1. **Guide AI agents** to build enterprise Next.js applications efficiently
2. **Eliminate project-specific references** (like "Avocado HP")
3. **Provide concrete examples** using generic entities (Resource, Category, User)
4. **Maintain production-quality patterns** from real-world applications

---

## 🏗️ **Repository Structure**

### **Core Files (Production Ready)**

```
core/
├── 01-ARCHITECTURE.md ........... ✅ Universal tech stack patterns
├── 02-DEVELOPMENT.md ............ ✅ Universal development workflow
├── 03-DATA-PATTERNS.md .......... ✅ Universal database patterns
├── 04-AUTH-PATTERNS.md .......... 🔄 Needs universalization
├── 05-SERVICE-PATTERNS.md ....... 🔄 Needs universalization
├── 06-API-PATTERNS.md ........... 🔄 Needs universalization
├── 07-COMPONENT-PATTERNS.md ..... 🔄 Needs universalization
├── 08-TESTING-STRATEGY.md ....... 🔄 Needs universalization
├── 09-ERROR-HANDLING.md ......... 🔄 Needs universalization
├── 10-EMAIL-PATTERNS.md ......... 🔄 Needs universalization
├── 11-DEPLOYMENT.md ............. 🔄 Needs universalization
```

### **Support Directories**

```
├── api/ ......................... ✅ API-specific patterns
├── components/ .................. 📝 Component-specific patterns
├── data/ ........................ ✅ Data layer deep-dive
├── patterns/ .................... 📝 Advanced patterns
├── improvements/ ................ ✅ Future enhancements
└── templates/ ................... 📝 Customizable templates
```

---

## 📋 **Universal Patterns Standards**

### **Entity Examples (Use These)**

- **Resource** - Generic business entity
- **Category** - Classification/grouping entity
- **User** - Authentication entity
- **Profile** - User profile/role entity

### **Avoid Project-Specific Terms**

- ❌ "Avocado HP", "Supplier", "Machinery", "Equipment"
- ❌ Company names, specific business domains
- ❌ Portuguese text in code examples
- ❌ Hardcoded URLs or repository names

### **Code Pattern Requirements**

- ✅ English error messages in Zod schemas
- ✅ Generic field names (name, description, type, status)
- ✅ Consistent audit fields (createdAt, updatedAt, createdById, updatedById)
- ✅ Soft delete pattern with Status enum
- ✅ kebab-case for file/component names

---

## �️ **Global Roadmap & Progress**

### **🎯 Project Progress: 27% Complete**

```
Phase 1: Foundation (MVP) ████████████░░░░░░░░░░░░░░░░░░░░ 40% (4/10)
Phase 2: Core Features     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  0% (0/7)
Phase 3: Advanced Features ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  0% (0/5)
```

---

### **📋 Phase 1: Foundation (MVP) - 40% Complete**

> **Goal**: Universal documentation boilerplate ready for production use

**✅ Completed (4/10)**

- ✅ **Project Structure** - Repository organization and AI context
- ✅ **README.md** - User-facing project presentation
- ✅ **02-DEVELOPMENT.md** - Universal development workflow
- ✅ **03-DATA-PATTERNS.md** - Universal database patterns

**🔄 In Progress (6/10)**

- 🔄 **04-AUTH-PATTERNS.md** - Authentication with Better Auth (Next Priority)
- 🔄 **05-SERVICE-PATTERNS.md** - Business logic patterns
- 🔄 **06-API-PATTERNS.md** - API endpoint patterns
- 🔄 **07-COMPONENT-PATTERNS.md** - React component patterns
- 🔄 **08-TESTING-STRATEGY.md** - Integration testing patterns
- 🔄 **09-ERROR-HANDLING.md** - Error handling patterns

**📊 MVP Success Criteria**

- [ ] All 10 core files universalized and AI-ready
- [ ] No project-specific references in any file
- [ ] All examples use Resource/Category/User entities
- [ ] Complete AI prompt templates for each pattern area
- [ ] Production-ready patterns for immediate use

---

### **📋 Phase 2: Core Features - 0% Complete**

> **Goal**: Enhanced documentation with advanced patterns and tools

**🎯 Planned Features (0/7)**

- 🎯 **10-EMAIL-PATTERNS.md** - Transactional email patterns
- 🎯 **11-DEPLOYMENT.md** - Docker, CI/CD & production deployment
- 🎯 **Template System Enhancement** - Dynamic placeholder replacement
- 🎯 **Setup Script Improvement** - Automated project initialization
- 🎯 **Component Library Patterns** - Advanced UI component patterns
- 🎯 **Performance Optimization** - Query optimization and caching patterns
- 🎯 **Security Patterns** - Authentication, authorization, and data protection

**📊 Core Features Success Criteria**

- [ ] Complete email and deployment documentation
- [ ] Automated setup tools working perfectly
- [ ] Advanced patterns for complex enterprise needs
- [ ] Performance and security best practices documented

---

### **📋 Phase 3: Advanced Features - 0% Complete**

> **Goal**: Ecosystem expansion and community features

**🚀 Future Enhancements (0/5)**

- 🚀 **VS Code Extension** - Automatic boilerplate setup and navigation
- 🚀 **Interactive Documentation** - Searchable, filterable pattern library
- 🚀 **Domain-Specific Templates** - E-commerce, CRM, HR systems templates
- 🚀 **Community Contributions** - User-submitted patterns and examples
- 🚀 **AI Training Dataset** - Optimized dataset for fine-tuning AI models

**📊 Advanced Features Success Criteria**

- [ ] VS Code extension with 1k+ installations
- [ ] 5+ domain-specific template libraries
- [ ] Active community contributing patterns
- [ ] Documentation used by 100+ projects

---

### **🎯 Current Focus & Next Steps**

**📍 Where We Are**: Foundation phase with core documentation patterns established
**🎯 Next Milestone**: Complete Phase 1 MVP (6 files remaining)
**⏰ Estimated Timeline**: 2-3 development sessions to complete MVP

**🔥 Immediate Priorities**

1. **04-AUTH-PATTERNS.md** - Authentication patterns (Critical for MVP)
2. **05-SERVICE-PATTERNS.md** - Business logic patterns
3. **06-API-PATTERNS.md** - API endpoint patterns

**📈 Progress Update Rules**

- Update percentage after each file completion
- Move completed items from 🔄 to ✅
- Adjust timeline estimates based on actual completion time
- Update success criteria as patterns evolve

---

## �🔄 **Current Development Status**

### **Completed Universalization**

- ✅ **README.md** - User-facing project presentation
- ✅ **02-DEVELOPMENT.md** - Universal development workflow
- ✅ **03-DATA-PATTERNS.md** - Universal database patterns with Resource/Category examples

### **Next Priority Files**

1. **04-AUTH-PATTERNS.md** - Authentication with Better Auth
2. **05-SERVICE-PATTERNS.md** - Business logic patterns
3. **06-API-PATTERNS.md** - API endpoint patterns
4. **07-COMPONENT-PATTERNS.md** - React component patterns

### **Pattern Consistency Goals**

- All examples use Resource/Category/User entities
- All validation messages in English
- All file names use kebab-case
- All patterns include audit trail examples

---

## 🎯 **AI Agent Guidelines**

### **When Universalizing Files**

1. **Read existing content** to understand the pattern intent
2. **Replace project-specific examples** with Resource/Category/User patterns
3. **Maintain functional complexity** - don't oversimplify
4. **Keep production-quality** patterns intact
5. **Add references** to detailed documentation files

### **File Structure Pattern**

```markdown
# 📁 [TOPIC] Patterns

## Overview

Brief explanation of the pattern area

## Quick Examples

Rapid-reference patterns for AI agents

## Detailed Documentation

References to ./[topic]/ detailed files

## AI Agent Guidelines

Specific guidance for implementing this pattern
```

### **Documentation References**

- Link to detailed files: `./data/`, `./api/`, `./components/`
- Reference future improvements: `./improvements/`
- Maintain backward compatibility with existing links

---

## � **Progressive Development Protocol**

### **Mandatory Update Cycle**

After completing any development task, **ALWAYS update this AI-CONTEXT.md file** with:

1. **Progress Status** - Move completed files from 🔄 to ✅
2. **New Patterns Discovered** - Add any new standards or conventions
3. **Changed Priorities** - Update "Next Priority Files" based on new insights
4. **Quality Improvements** - Add new success metrics or quality indicators

### **Update Triggers**

Update this file when:

- ✅ **File Universalization Complete** - Update status and add learnings
- 🎯 **New Pattern Identified** - Add to standards section
- 🔄 **Priority Changes** - Reorder next files based on dependencies
- 🐛 **Issue Resolution** - Add new quality checks or standards
- 💡 **Process Improvement** - Update development guidelines

### **Continuous Learning Protocol**

```markdown
## 📝 Development Log Entry Template

### [DATE] - [TASK COMPLETED]

**Status Change**: [File] moved from 🔄 to ✅
**Progress Update**: [Update percentage and phase progress]
**New Patterns**: [Describe any new patterns discovered]
**Updated Standards**: [Any changes to universal patterns]
**Next Priorities**: [Updated priority list]
**Timeline Adjustment**: [Any changes to roadmap timeline]
**Quality Notes**: [Lessons learned for future files]
**Commit Info**: [Commit hash and brief description of changes pushed to GitHub]
```

---

## 📝 **Development History Log**

### 2025-08-02 - Data Patterns Universalization Complete

**Status Change**: 03-DATA-PATTERNS.md moved from 🔄 to ✅
**New Patterns**:

- Implicit many-to-many relationships managed by Prisma
- References to detailed documentation for complex patterns
  **Updated Standards**:
- Removed pagination from basic examples
- Enhanced validation schemas with relationship patterns
  **Next Priorities**: Auth patterns remain top priority
  **Quality Notes**: Universal entities (Resource/Category) work well for complex relationships

### 2025-08-02 - AI Context Framework & Roadmap Created

**Status Change**: AI-CONTEXT.md created ✅
**Progress Update**: Project progress established at 27% (Phase 1: 40% complete)
**New Patterns**:

- Progressive development protocol with roadmap tracking
- Three-phase development approach (Foundation → Core → Advanced)
- Separation of user-facing vs AI-context documentation
  **Updated Standards**:
- Mandatory roadmap and percentage updates after each completion
- Timeline estimation and adjustment protocols
  **Next Priorities**: Continue with 04-AUTH-PATTERNS.md (Critical for MVP completion)
  **Timeline Adjustment**: Estimated 2-3 sessions to complete Phase 1 MVP
  **Quality Notes**: Dedicated AI context with roadmap improves development predictability

---

## �🚀 **Success Metrics**

### **Quality Indicators**

- ✅ No project-specific terms in any file
- ✅ All code examples use universal entities
- ✅ All validation messages in English
- ✅ Consistent file naming (kebab-case)
- ✅ Clear AI agent prompt templates

### **Usability Tests**

- Can an AI agent understand the pattern without context?
- Can patterns be copied to any Next.js project?
- Are examples concrete enough to implement immediately?
- Do patterns scale to enterprise complexity?

---

## 💡 **Development Philosophy**

> **"Universal yet Concrete"** - Provide patterns that work for any business domain while being specific enough for immediate implementation.

### **Key Principles**

1. **AI-First Design** - Every pattern should be immediately usable by AI agents
2. **Production Quality** - All patterns from real-world applications
3. **Universal Applicability** - No project-specific dependencies
4. **Concrete Examples** - Generic but implementable patterns
5. **Consistent Structure** - Same format across all files

---

## 🛠️ **Quick Commands for Development**

```bash
# Check for project-specific terms
grep -r "Avocado\|HP\|supplier\|machinery" core/

# Validate kebab-case naming
find . -name "*.md" | grep -v kebab-case-pattern

# Test universal patterns
# (Check if examples use Resource/Category/User entities)
```

---

## 🎯 **Development Workflow**

### **Before Starting Any Task**

1. 📖 **Read AI-CONTEXT.md** - Understand current status and standards
2. 🎯 **Check Next Priorities** - Confirm you're working on the right file
3. 📋 **Review Universal Standards** - Ensure consistency with established patterns

### **During Development**

1. 🔍 **Follow Universal Patterns** - Use Resource/Category/User entities
2. 📝 **Maintain Quality Standards** - English messages, kebab-case, audit fields
3. 🔗 **Add Proper References** - Link to detailed documentation files

### **After Completing Any Task**

1. ✅ **Update Status** - Move completed files from 🔄 to ✅
2. � **Update Progress** - Recalculate percentage and phase completion
3. �📝 **Add Development Log Entry** - Document what was learned
4. 🎯 **Update Next Priorities** - Based on new insights or dependencies
5. 🗺️ **Update Roadmap** - Adjust timeline and milestones if needed
6. 🧪 **Run Quality Checks** - Validate patterns meet success metrics

### **Development Session Checklist**

- [ ] AI-CONTEXT.md read and understood
- [ ] Current roadmap phase and priorities confirmed
- [ ] Universal patterns followed consistently
- [ ] Quality standards met (no project-specific terms)
- [ ] References to detailed docs added where needed
- [ ] AI-CONTEXT.md updated with progress
- [ ] Roadmap percentage and phase progress updated
- [ ] Development log entry added
- [ ] Next priorities updated if needed
- [ ] Changes committed and pushed to GitHub repository

---

**🎯 Remember: This AI-CONTEXT.md is the single source of truth for development standards and progress. Keep it updated to maintain project consistency and quality.**
