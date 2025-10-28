# Terraform RocketChat Deployments

**Deterministic, production-ready RocketChat deployments on AWS and Azure using Terraform + Kubernetes.**

[![Phase B](https://img.shields.io/badge/Phase%20B-Complete-success)](DOCs/PHASE-B-COMPLETION.md)
[![Deployment Ready](https://img.shields.io/badge/Deployment-Ready-brightgreen)](DOCs/PHASE-B-READINESS.md)
[![Terraform](https://img.shields.io/badge/Terraform-1.9+-blue)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-orange)](AWS/)
[![Azure](https://img.shields.io/badge/Azure-AKS-blue)](AZURE/)

---

## ✨ Key Features

- ✅ **Deterministic Deployments**: Deploy → Destroy → Deploy = identical resource names
- ✅ **Version Pinned**: All Terraform providers, Helm charts, and container images pinned
- ✅ **Multi-Cloud**: Same codebase for AWS EKS and Azure AKS
- ✅ **Production Ready**: HA MongoDB, auto-scaling, full monitoring stack
- ✅ **Best Practices**: Uses `terraform plan -out` for safe deployments
- ✅ **Environment Support**: Sandbox, dev, prod with environment-specific tfvars
- ✅ **Deployment Ready**: All Phase 0/A issues resolved (see [PHASE-B-READINESS.md](DOCs/PHASE-B-READINESS.md))

**Status**: Phase B Complete ✅ | Phase C Next 🔜 | Deployment Ready 🟢

---

## 📋 Getting Started

### 🎯 **Quick Links**

- 🟢 **[PHASE-B-READINESS.md](DOCs/PHASE-B-READINESS.md)** - ALL CLEAR for deployment ← **START HERE**
- **[MASTER-PLAN.md](DOCs/MASTER-PLAN.md)** - Complete implementation roadmap
- **[PHASE-B-COMPLETION.md](DOCs/PHASE-B-COMPLETION.md)** - Phase B completion details
- **[PHASE-A-SUMMARY.md](DOCs/PHASE-A-SUMMARY.md)** - Phase A completion details
- **[azure-sandbox-setup.md](DOCs/azure-sandbox-setup.md)** - Azure sandbox setup guide
- **[DEPLOYMENT-CHECKLIST.md](DOCs/DEPLOYMENT-CHECKLIST.md)** - Deployment checklist

### 📅 Implementation Phases

| Phase | Status | Duration | Description |
|-------|--------|----------|-------------|
| **Phase 0** | ✅ Complete | 1 hr | Fix critical bugs (App Gateway, Helm charts) |
| **Phase A** | ✅ Complete | 4-6 hrs | Deterministic deployments + version pinning |
| **Phase B** | ✅ Complete | 4-6 hrs | Environment-specific tfvars (sandbox/dev/prod) |
| **Phase C** | 🔜 Next | 3-4 hrs | Remote state backend (S3/Azure Storage) |

---

## 🚀 Quick Start

### Prerequisites
- Terraform 1.9+ installed
- Cloud CLI configured (AWS CLI or Azure CLI)
- kubectl and helm installed

### AWS Deployment
```bash
cd AWS/terraform

# Initialize Terraform
terraform init -upgrade

# Plan deployment (REQUIRED: use -out flag)
terraform plan -var="deployment_id=dev123" -out deploy.tfplan

# Review the plan, then apply
terraform apply deploy.tfplan
```

### Azure Deployment

**🟢 DEPLOYMENT READY**: All Phase 0/A issues resolved. See [PHASE-B-READINESS.md](DOCs/PHASE-B-READINESS.md) for full assessment.

**Phase B: Use environment-specific tfvars**:
```bash
cd AZURE/terraform

# Initialize Terraform
terraform init -upgrade

# Sandbox (cost-optimized, 2 nodes)
terraform plan -var-file=terraform.sandbox.tfvars -out=sandbox.tfplan
terraform apply sandbox.tfplan

# Development
terraform plan -var-file=terraform.dev.tfvars -out=dev.tfplan
terraform apply dev.tfplan

# Production (full resources)
terraform plan -var-file=terraform.prod.tfvars -out=prod.tfplan
terraform apply prod.tfplan
```

**Legacy: Manual deployment_id** (not recommended):
```bash
cd AZURE/terraform

# Plan deployment (REQUIRED: use -out flag)
terraform plan -var="deployment_id=sandbox01" -out aks.tfplan

# Review the plan, then apply
terraform apply aks.tfplan
```

**Important**: Always use `terraform plan -out` to save plans before applying. This ensures what you review is exactly what gets deployed.

---

## 📁 Project Structure

```
Terraform_RC_deployments/
├── AWS/                    # AWS EKS deployment
│   ├── terraform/          # Terraform configuration
│   ├── helm/               # Helm values files
│   └── scripts/            # Deployment scripts
├── AZURE/                  # Azure AKS deployment
└── DOCs/                   # Documentation
    ├── MASTER-PLAN.md      # 🎯 START HERE - Implementation roadmap
    ├── deployment.md       # Deployment guide
    ├── troubleshooting.md  # Troubleshooting guide
    ├── architecture.md     # Architecture overview
    ├── operations.md       # Day-2 operations
    └── INDEX.md            # Documentation index
```

---

## 🏗️ Architecture Overview

### AWS EKS Deployment
- **EKS Cluster**: Managed Kubernetes cluster
- **RocketChat**: 2 replicas with auto-scaling
- **MongoDB**: 3-replica set for high availability
- **Load Balancer**: Application Load Balancer (ALB)
- **Storage**: EBS volumes + S3 for file uploads
- **Monitoring**: Prometheus + Grafana stack
- **Networking**: VPC with public/private subnets

### Azure AKS Deployment
- **AKS Cluster**: Managed Kubernetes cluster
- **RocketChat**: 2 replicas with auto-scaling
- **MongoDB**: 3-replica set for high availability
- **Load Balancer**: Application Gateway
- **Storage**: Azure Disks + Blob Storage for file uploads
- **Monitoring**: Prometheus + Grafana stack
- **Networking**: VNet with public/private subnets

### Deployed Components
- **RocketChat**: Latest (microservices architecture)
- **MongoDB**: 3-replica set with persistence
- **Monitoring Stack**:
  - Prometheus (v52.0.0) - Metrics collection
  - Grafana (v6.50.0, image 11.4.0) - Dashboards
  - Loki (v6.20.0) - Log aggregation
  - Tempo (v1.23.3) - Distributed tracing
- **Storage**: Cloud-native persistent volumes + object storage
- **Networking**: Load balancer with health checks

### Deterministic Naming (Phase A)
All resources use `deployment_id` for predictable names:
- **AWS**: `{deployment_id}-eks`, `{deployment_id}-rc-files-{region}`
- **Azure**: `{deployment_id}-aks`, `{deployment_id}rcfiles`, `{deployment_id}-aks-vnet`

**Example**: `deployment_id=sandbox01` creates `sandbox01-aks`, `sandbox01rcfiles`, etc.

---

## 📋 Prerequisites

### Required Tools
- **Terraform** (v1.9+) - [Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **kubectl** (v1.28+) - [Install Guide](https://kubernetes.io/docs/tasks/tools/)
- **Helm** (v3.0+) - [Install Guide](https://helm.sh/docs/intro/install/)

### Cloud-Specific Requirements

**AWS**:
- AWS CLI configured with credentials
- IAM permissions for EKS, VPC, S3, IAM, CloudWatch

**Azure**:
- Azure CLI installed
- Service Principal with Contributor access
- Resource Group access (sandbox or dedicated)
- See [azure-sandbox-setup.md](DOCs/azure-sandbox-setup.md) for sandbox setup

### Version Pinning (Phase A Complete)
All versions are pinned for reproducibility:
- **Terraform Providers**: AWS 5.76, Azure 3.117, Helm 2.17, Kubernetes 2.38
- **Helm Charts**: Prometheus 52.0.0, Grafana 6.50.0, Loki 6.20.0, Tempo 1.23.3
- **Container Images**: Grafana 11.4.0, RocketChat 7.0.0

---

## 🔧 Best Practices

### Terraform Workflow (REQUIRED)
Always use plan files to ensure consistency:

```bash
# 1. Plan and save to file
terraform plan -var="deployment_id=myenv" -out myenv.tfplan

# 2. Review the plan output carefully

# 3. Apply the saved plan (no drift between plan and apply)
terraform apply myenv.tfplan
```

**Why?** Using `-out` ensures what you review in `plan` is exactly what gets deployed in `apply`, preventing unexpected changes.

### Deployment ID Convention
Use descriptive, environment-specific IDs:
- Sandbox: `sandbox01`, `sandbox02`
- Dev: `dev-feature-x`, `dev-team-a`
- Staging: `staging-v2`
- Production: `prod-us-east`, `prod-eu-west`

**Rules**: 3-16 characters, lowercase alphanumeric and hyphens only

---

## 📚 Documentation

### Getting Started
- **[MASTER-PLAN.md](DOCs/MASTER-PLAN.md)** - Complete implementation roadmap (all phases)
- **[azure-sandbox-setup.md](DOCs/azure-sandbox-setup.md)** - Azure sandbox setup guide
- **[DEPLOYMENT-CHECKLIST.md](DOCs/DEPLOYMENT-CHECKLIST.md)** - Pre-flight checklist

### Phase Summaries
- **[PHASE-A-SUMMARY.md](DOCs/PHASE-A-SUMMARY.md)** - Deterministic deployments (COMPLETE ✅)
- **[PHASE-0-COMPLETION.md](DOCs/PHASE-0-COMPLETION.md)** - Bug fixes (COMPLETE ✅)

### Reference
- [deployment.md](DOCs/deployment.md) - Step-by-step deployment guide
- [troubleshooting-aws.md](DOCs/troubleshooting-aws.md) - AWS-specific issues
- [troubleshooting-azure.md](DOCs/troubleshooting-azure.md) - Azure-specific issues
- [architecture.md](DOCs/architecture.md) - Technical architecture overview
- [operations.md](DOCs/operations.md) - Day-2 operations and maintenance
- [INDEX.md](DOCs/INDEX.md) - Documentation index

---

## 🔍 Verification

After deployment, verify your installation:

```bash
# Check cluster status
kubectl get nodes

# Check RocketChat
kubectl get pods -n rocketchat

# Check monitoring
kubectl get pods -n monitoring

# Get access URLs
terraform output
```

---

## 🧹 Cleanup

To destroy all resources (best practice with plan files):

```bash
# AWS
cd AWS/terraform
terraform plan -destroy -var="deployment_id=dev123" -out destroy.tfplan
terraform apply destroy.tfplan

# Azure
cd AZURE/terraform
terraform plan -destroy -var="deployment_id=sandbox01" -out destroy.tfplan
terraform apply destroy.tfplan
```

**Note**: For Azure sandbox, the resource group itself won't be deleted (you don't own it), only resources inside it.

---

## 🆘 Support

### Common Issues

**Azure Sandbox**:
- See [azure-sandbox-setup.md](DOCs/azure-sandbox-setup.md) for setup issues
- See [troubleshooting-azure.md](DOCs/troubleshooting-azure.md) § 9 for Loki issues

**AWS**:
- See [troubleshooting-aws.md](DOCs/troubleshooting-aws.md) for AWS-specific issues

**General**:
1. Check [MASTER-PLAN.md](DOCs/MASTER-PLAN.md) for implementation guidance
2. Check [DEPLOYMENT-CHECKLIST.md](DOCs/DEPLOYMENT-CHECKLIST.md) for pre-flight checks
3. Review Terraform and Kubernetes logs
4. Check cloud provider documentation

### Getting Help
1. Review the documentation in `DOCs/`
2. Check the troubleshooting guides for your cloud
3. Verify all prerequisites are met
4. Open an issue in this repository with logs and error messages

---

## 🏷️ Tags

- **Project**: RocketChat
- **Environment**: Production
- **ManagedBy**: Terraform
- **Owner**: DevOps Team

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📞 Contact

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Documentation**: [Project Wiki](https://github.com/your-repo/wiki)
- **Support**: [Contact Form](https://your-support-form.com)

---

**👉 Start with [DOCs/MASTER-PLAN.md](DOCs/MASTER-PLAN.md) for complete implementation guide**

**Happy Deploying! 🚀**
