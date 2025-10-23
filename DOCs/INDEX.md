# Documentation Index & Navigation

**Last Updated**: October 23, 2025  
**Current Phase**: ✅ Phase 0 COMPLETE → Next: Phase A (Make Deterministic)

**Quick Jump**: 
- **Phase 0 Complete?** → See [PHASE-0-COMPLETION.md](PHASE-0-COMPLETION.md) for summary
- **Starting Phase A?** → See [MASTER-PLAN.md](MASTER-PLAN.md) Phase A section + checklist
- **Need Help?** → [troubleshooting-azure.md](troubleshooting-azure.md) or [troubleshooting-aws.md](troubleshooting-aws.md)

---

## 🎯 START HERE

### **[MASTER-PLAN.md](MASTER-PLAN.md)** ← Read This First

Your complete roadmap with all phases clearly defined. Contains everything you need to build a reusable Terraform template that works for AWS + Azure.

**Then use**: **[DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)** to track progress

---

## 📋 Phase Implementation (Use Cursor)

Keep **MASTER-PLAN.md** and **DEPLOYMENT-CHECKLIST.md** open while implementing:

1. **Phase 0** (1 hour): Fix critical bugs + Deploy monitoring
   - Lines: "## 🚀 Phase 0" in MASTER-PLAN.md
   - Use: DEPLOYMENT-CHECKLIST.md → Phase 0 section

2. **Phase A** (4-6 hours): Make deterministic
   - Lines: "## 🎯 Phase A" in MASTER-PLAN.md
   - Use: DEPLOYMENT-CHECKLIST.md → Phase A section

3. **Phase B** (4-6 hours): Multi-environment support
   - Lines: "## 🌍 Phase B" in MASTER-PLAN.md
   - Use: DEPLOYMENT-CHECKLIST.md → Phase B section

4. **Phase C** (3-4 hours): Remote state backend
   - Lines: "## 🔐 Phase C" in MASTER-PLAN.md
   - Use: DEPLOYMENT-CHECKLIST.md → Phase C section

---

## 📚 Reference Documentation

### Getting Started
- **[DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)** - Complete step-by-step checklist with commands

### Architecture & Design
- **[architecture.md](architecture.md)** - High-level design, components, AWS vs Azure comparison
- **[deployment.md](deployment.md)** - Step-by-step deployment for AWS and Azure

### Operations & Monitoring
- **[operations.md](operations.md)** - Day-2 operations, scaling, backups (AWS + Azure)
- **[monitoring-stack.md](monitoring-stack.md)** - Complete Prometheus + Grafana + Loki + Tempo guide

### Troubleshooting
- **[troubleshooting.md](troubleshooting.md)** - Navigation guide for cloud-specific troubleshooting
  - **[troubleshooting-aws.md](troubleshooting-aws.md)** - AWS EKS-specific issues
  - **[troubleshooting-azure.md](troubleshooting-azure.md)** - Azure AKS-specific issues

---

## 🚀 Quick Navigation

### By Task
| Need... | Go to... |
|---------|----------|
| Complete deployment with checklist | [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) |
| First time setup (detailed) | [MASTER-PLAN.md](MASTER-PLAN.md) → Phase 0 |
| Deploy to AWS | [deployment.md](deployment.md) → AWS section |
| Deploy to Azure | [deployment.md](deployment.md) → Azure section |
| Fix an issue on AWS | [troubleshooting-aws.md](troubleshooting-aws.md) |
| Fix an issue on Azure | [troubleshooting-azure.md](troubleshooting-azure.md) |
| Scale cluster | [operations.md](operations.md) → Scaling section |
| Setup monitoring | [monitoring-stack.md](monitoring-stack.md) |

### By Cloud
| Platform | Deploy | Troubleshoot |
|----------|--------|--------------|
| **AWS EKS** | [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md#aws-deployment) | [troubleshooting-aws.md](troubleshooting-aws.md) |
| **Azure AKS** | [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md#azure-deployment) | [troubleshooting-azure.md](troubleshooting-azure.md) |

---

## 📊 Monitoring Stack Components

Fully integrated observability:
- **Prometheus**: Metrics collection and alerting
- **Loki**: Log aggregation and querying
- **Tempo**: Distributed tracing
- **Grafana**: Visualization and dashboards

See **[monitoring-stack.md](monitoring-stack.md)** for setup and integration details.

---

## 📁 File Organization

```