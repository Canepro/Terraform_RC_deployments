# RocketChat Deployment Checklist (AWS + Azure)

**Complete roadmap for deploying RocketChat + Full Monitoring Stack**

---

## 📋 Pre-Deployment Checklist

### AWS Prerequisites
- [ ] AWS Account with appropriate permissions
- [ ] AWS CLI configured (`aws configure`)
- [ ] IAM user/role with EKS, EC2, S3, IAM permissions
- [ ] Terraform installed (`terraform -v`)
- [ ] kubectl installed (`kubectl version`)
- [ ] Helm installed (`helm version`)

### Azure Prerequisites
- [ ] Azure Account with sandbox or subscription
- [ ] Azure CLI installed (`az --version`)
- [ ] Logged in to Azure (`az login`)
- [ ] Terraform installed (`terraform -v`)
- [ ] kubectl installed (`kubectl version`)
- [ ] Helm installed (`helm version`)

### Common Prerequisites (Both Clouds)
- [ ] Docker installed (for local testing)
- [ ] Git configured
- [ ] Text editor with Terraform support (VS Code, Cursor)

---

## 🚀 Phase 0: Deploy Working Infrastructure (1 Hour)

### AWS Deployment

```bash
# 1. Navigate to AWS Terraform directory
cd AWS/terraform

# 2. Initialize Terraform
terraform init

# 3. Review planned changes
terraform plan

# 4. Deploy infrastructure
terraform apply -auto-approve

# 5. Get kubeconfig
aws eks update-kubeconfig --name rocketchat-eks-production --region us-east-1

# 6. Verify cluster access
kubectl get nodes
```

**Checklist**:
- [ ] Terraform initialization successful
- [ ] No errors in `terraform plan`
- [ ] `terraform apply` completed
- [ ] `kubectl get nodes` shows worker nodes
- [ ] RocketChat pod running: `kubectl get pods -n rocketchat`
- [ ] Grafana accessible: `kubectl get svc -n monitoring`

### Azure Deployment

```bash
# 1. Navigate to Azure Terraform directory
cd AZURE/terraform

# 2. Initialize Terraform
terraform init

# 3. Review planned changes
terraform plan

# 4. Deploy infrastructure
terraform apply -auto-approve

# 5. Get kubeconfig
az aks get-credentials \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks

# 6. Verify cluster access
kubectl get nodes
```

**Checklist**:
- [ ] Terraform initialization successful
- [ ] No errors in `terraform plan`
- [ ] `terraform apply` completed
- [ ] `kubectl get nodes` shows worker nodes
- [ ] RocketChat pod running: `kubectl get pods -n rocketchat`
- [ ] Application Gateway endpoints healthy: `az network application-gateway show`

---

## 📊 Phase 0b: Verify Monitoring Stack

### All Monitoring Components Deployed

```bash
# Check all monitoring pods
kubectl get pods -n monitoring

# Expected pods:
# - prometheus-*
# - grafana-*
# - loki-*
# - tempo-*
# - promtail-* (DaemonSet)
```

**Checklist**:
- [ ] Prometheus pod running
- [ ] Grafana pod running
- [ ] Loki pod running
- [ ] Tempo pod running
- [ ] Promtail DaemonSet running on all nodes
- [ ] All pods in "Running" state

### Verify Datasource Connectivity

```bash
# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# In another terminal, test datasources
kubectl exec -n monitoring <grafana-pod> -- \
  curl -s http://prometheus-server:9090/-/healthy

kubectl exec -n monitoring <grafana-pod> -- \
  curl -s http://loki:3100/ready

kubectl exec -n monitoring <grafana-pod> -- \
  curl -s http://tempo:3200/ready
```

**Checklist**:
- [ ] Grafana accessible at http://localhost:3000
- [ ] Prometheus datasource healthy
- [ ] Loki datasource healthy
- [ ] Tempo datasource healthy
- [ ] Default Grafana dashboards visible

---

## 🎯 Phase A: Make Infrastructure Deterministic (4-6 Hours)

### Add Deployment ID and Version Pinning

**Files to Update**:
- [ ] `AWS/terraform/variables.tf` - Add deployment_id, version variables
- [ ] `AZURE/terraform/variables.tf` - Add deployment_id, version variables
- [ ] `AWS/terraform/terraform.tfvars` - Add deployment_id value
- [ ] `AZURE/terraform/terraform.tfvars` - Add deployment_id value

### Update Storage Account Naming

**Files to Update**:
- [ ] `AWS/terraform/s3.tf` - Use deterministic naming
- [ ] `AZURE/terraform/storage.tf` - Remove random strings, use deployment_id

### Pin All Helm Versions

**Files to Update**:
- [ ] `AWS/terraform/helm.tf` - Add version constraints
- [ ] `AZURE/terraform/helm.tf` - Add version constraints

**Verification**:
```bash
# Deploy, destroy, deploy again - should have identical names
terraform apply -auto-approve
terraform destroy -auto-approve
terraform apply -auto-approve

# Check resource names match exactly
aws s3 ls  # or az storage account list
```

**Checklist**:
- [ ] S3 bucket names deterministic (AWS)
- [ ] Storage account names deterministic (Azure)
- [ ] All Helm chart versions pinned
- [ ] Deploy → Destroy → Deploy produces identical resources

---

## 🌍 Phase B: Multi-Environment Support (4-6 Hours)

### Create Environment-Specific tfvars Files

**Files to Create**:
- [ ] `AWS/terraform/terraform.sandbox.tfvars`
- [ ] `AWS/terraform/terraform.dev.tfvars`
- [ ] `AWS/terraform/terraform.prod.tfvars`
- [ ] `AZURE/terraform/terraform.sandbox.tfvars`
- [ ] `AZURE/terraform/terraform.dev.tfvars`
- [ ] `AZURE/terraform/terraform.prod.tfvars`

### Deploy to Each Environment

```bash
# AWS - Sandbox
cd AWS/terraform
terraform plan -var-file=terraform.sandbox.tfvars
terraform apply -var-file=terraform.sandbox.tfvars -auto-approve

# AWS - Dev
terraform plan -var-file=terraform.dev.tfvars
terraform apply -var-file=terraform.dev.tfvars -auto-approve

# AWS - Production
terraform plan -var-file=terraform.prod.tfvars
terraform apply -var-file=terraform.prod.tfvars -auto-approve
```

**Checklist**:
- [ ] Sandbox environment deployed and accessible
- [ ] Dev environment deployed and accessible
- [ ] Production environment deployed and accessible
- [ ] Different resource naming per environment
- [ ] Network isolation between environments
- [ ] Each environment has independent monitoring

---

## 🔐 Phase C: Remote State Backend (3-4 Hours)

### AWS Remote State

**Files to Update**:
- [ ] `AWS/terraform/versions.tf` - Add S3 backend configuration

```hcl
backend "s3" {
  bucket         = "terraform-state-ACCOUNT-ID"
  key            = "rocketchat/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

**Setup Steps**:
```bash
# Create S3 bucket for state
aws s3 mb s3://terraform-state-$(aws sts get-caller-identity --query Account -o text)

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
```

**Checklist**:
- [ ] S3 bucket created
- [ ] Versioning enabled on S3 bucket
- [ ] DynamoDB table created
- [ ] backend.tf updated
- [ ] `terraform init` reinitializes with remote backend
- [ ] State file in S3

### Azure Remote State

**Files to Update**:
- [ ] `AZURE/terraform/versions.tf` - Add Azure backend configuration

```hcl
backend "azurerm" {
  resource_group_name  = "terraform-state"
  storage_account_name = "tfstate<random>"
  container_name       = "tfstate"
  key                  = "rocketchat/terraform.tfstate"
}
```

**Setup Steps**:
```bash
# Create resource group
az group create \
  --name terraform-state \
  --location eastus

# Create storage account
az storage account create \
  --resource-group terraform-state \
  --name tfstate$(date +%s) \
  --sku Standard_LRS

# Create container
az storage container create \
  --name tfstate \
  --account-name <storage-account-name>
```

**Checklist**:
- [ ] Resource group created
- [ ] Storage account created
- [ ] Container created
- [ ] backend.tf updated
- [ ] `terraform init` reinitializes with remote backend
- [ ] State file in Azure Storage

---

## ✅ Post-Deployment: Monitoring Verification

### Access Monitoring Dashboards

```bash
# Get all service endpoints
kubectl get svc -n monitoring

# Get admin credentials
kubectl get secret grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d

# Port-forward for local access
kubectl port-forward -n monitoring svc/grafana 3000:3000 &
kubectl port-forward -n monitoring svc/prometheus-server 9090:9090 &
kubectl port-forward -n monitoring svc/loki 3100:3100 &
kubectl port-forward -n monitoring svc/tempo 3200:3200 &
```

### Verify Data Collection

**Prometheus**:
- [ ] Access http://localhost:9090
- [ ] Check Status → Targets (all should be "Up")
- [ ] Run query: `up` (should return metrics)

**Loki**:
- [ ] Access http://localhost:3100
- [ ] Verify logs are being collected
- [ ] Query: `{job="rocketchat"}`

**Tempo**:
- [ ] Access http://localhost:3200
- [ ] Check if traces are being collected
- [ ] Look for RocketChat services in service graph

**Grafana**:
- [ ] Access http://localhost:3000
- [ ] Login with admin credentials
- [ ] Verify all datasources connected
- [ ] Check RocketChat dashboards populated with data
- [ ] View logs in Loki datasource
- [ ] View traces in Tempo datasource

---

## 🗑️ Cleanup (Tear Down)

### AWS Cleanup

```bash
# Destroy all resources
cd AWS/terraform
terraform destroy -auto-approve

# Verify cleanup
aws eks list-clusters
aws s3 ls
aws ec2 describe-instances
```

**Checklist**:
- [ ] EKS cluster deleted
- [ ] EC2 instances terminated
- [ ] Security groups removed
- [ ] S3 buckets cleaned (or deleted)
- [ ] No orphaned resources

### Azure Cleanup

```bash
# Destroy all resources
cd AZURE/terraform
terraform destroy -auto-approve

# Verify cleanup
az aks list --output table
az vm list --output table
az storage account list --output table
```

**Checklist**:
- [ ] AKS cluster deleted
- [ ] Application Gateway deleted
- [ ] VMs terminated
- [ ] Storage accounts removed (or cleaned)
- [ ] Resource groups cleaned (or deleted)
- [ ] No orphaned resources

---

## 📊 Deployment Summary Matrix

| Phase | Task | AWS | Azure | Time |
|-------|------|-----|-------|------|
| 0 | Deploy infrastructure | ✅ | ✅ | 30 min |
| 0b | Deploy monitoring stack | ✅ | ✅ | 30 min |
| A | Deterministic naming | ✅ | ✅ | 2-3 hrs |
| B | Multi-environment | ✅ | ✅ | 2-3 hrs |
| C | Remote state backend | ✅ | ✅ | 1-2 hrs |

**Total Time**: ~12-14 hours

---

## 🎯 Success Criteria

✅ **Phase 0 Complete When**:
- RocketChat is accessible via ALB (AWS) or Application Gateway (Azure)
- All pods are running and healthy
- Monitoring stack collecting metrics, logs, and traces
- Grafana dashboards showing real-time data

✅ **Phase A Complete When**:
- Deploy → Destroy → Deploy produces identical resource names
- All versions pinned and reproducible
- tfvars files properly configured

✅ **Phase B Complete When**:
- Separate deployments for sandbox, dev, prod
- Each environment has isolated networking
- Different resource prefixes per environment

✅ **Phase C Complete When**:
- Terraform state in remote backend (S3 or Azure Storage)
- State locking works (no concurrent applies)
- Team members can collaborate safely

---

## 📚 Reference Documentation

- [MASTER-PLAN.md](MASTER-PLAN.md) - Detailed implementation guide
- [deployment.md](deployment.md) - Deployment procedures
- [monitoring-stack.md](monitoring-stack.md) - Monitoring setup
- [troubleshooting-aws.md](troubleshooting-aws.md) - AWS issues
- [troubleshooting-azure.md](troubleshooting-azure.md) - Azure issues
- [operations.md](operations.md) - Day-2 operations

---

**Last Updated**: October 23, 2025  
**Status**: Ready for deployment on AWS + Azure  
**Monitoring Stack**: ✅ Prometheus + Grafana + Loki + Tempo
