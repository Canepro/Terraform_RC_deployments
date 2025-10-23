# Terraform RocketChat Deployments

This repository contains **Terraform-based Infrastructure as Code (IaC)** deployments for RocketChat on cloud platforms using Terraform and Kubernetes.

**For both AWS and Azure, with full support for any environment (sandbox, dev, staging, prod).**

---

## 📋 Getting Started

### 🎯 **→ [Read MASTER-PLAN.md](DOCs/MASTER-PLAN.md)**

Complete roadmap with clear phases to build a reusable template that works for:
- ✅ Deploy/destroy anytime
- ✅ Same infrastructure every time
- ✅ Any Azure environment
- ✅ AWS and Azure support

**Phases**: Phase 0 (1 hr) → Phase A (4-6 hrs) → Phase B (4-6 hrs) → Phase C (3-4 hrs) = **2 weeks total**

---

## 🚀 Quick Start

### AWS Deployment
```bash
cd AWS/terraform
terraform init
terraform plan
terraform apply
```

### Azure Deployment
```bash
cd AZURE/terraform
terraform init
terraform plan
terraform apply
```

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

### Key Features
- ✅ **Production Ready**: High availability, auto-scaling, monitoring
- ✅ **Secure**: Private subnets, IAM roles, encrypted storage
- ✅ **Observable**: Full monitoring stack with dashboards
- ✅ **Repeatable**: Complete IaC approach
- ✅ **Cost Optimized**: Right-sized resources, spot instances
- ✅ **Terraform Native**: Full Terraform state management
- ✅ **Modular**: Clean, maintainable Terraform code
- ✅ **Stateful**: Terraform state tracking for all resources

---

## 📋 Prerequisites

### Required Tools
- **Terraform** (v1.0+) - [Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **kubectl** (v1.28+) - [Install Guide](https://kubernetes.io/docs/tasks/tools/)
- **Helm** (v3.0+) - [Install Guide](https://helm.sh/docs/intro/install/)

### Cloud-Specific Requirements
- **AWS**: AWS CLI, AWS Account with appropriate permissions
- **Azure**: Azure CLI, Azure subscription with appropriate permissions

---

## 🔧 Terraform Benefits

### Why Terraform?
- **State Management**: Track all infrastructure changes
- **Plan & Apply**: Review changes before applying
- **Dependency Management**: Automatic resource ordering
- **Rollback Capability**: Easy infrastructure rollbacks
- **Team Collaboration**: Shared state and locking
- **Multi-Cloud**: Same tool for AWS and Azure

---

## 📚 Documentation

### Main
- **[MASTER-PLAN.md](DOCs/MASTER-PLAN.md)** ← Start here for implementation roadmap

### Reference
- [deployment.md](DOCs/deployment.md) - Step-by-step deployment guide
- [troubleshooting.md](DOCs/troubleshooting.md) - Common issues and solutions
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

To destroy all resources:

```bash
# AWS
cd AWS/terraform
terraform destroy

# Azure
cd AZURE/terraform
terraform destroy
```

---

## 🆘 Support

### Documentation
1. Check [MASTER-PLAN.md](DOCs/MASTER-PLAN.md) for implementation guidance
2. Check [troubleshooting.md](DOCs/troubleshooting.md) for common issues
3. Check [operations.md](DOCs/operations.md) for operational guidance

### Getting Help
1. Review the documentation in `DOCs/`
2. Check Terraform and Kubernetes logs
3. Check cloud provider documentation
4. Open an issue in this repository

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
