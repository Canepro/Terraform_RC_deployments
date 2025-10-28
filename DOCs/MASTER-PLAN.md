# Terraform Reusable Template - Master Plan

**Goal**: One template that deploys/destroys anytime, same every time, across ANY environment (AWS/Azure)

**Total Effort**: ~2 weeks | **Phases**: 3 | **Deliverable**: Production-ready, reusable template

---

## 📋 Executive Summary

You will build a **single reusable Terraform template framework** that works for:
- ✅ AWS EKS OR Azure AKS
- ✅ Any environment (sandbox, dev, staging, prod)
- ✅ Deploy/destroy/redeploy with identical results
- ✅ Team collaboration with state locking
- ✅ Works immediately (no manual edits per environment)

---

## 🎯 Phase Breakdown

| Phase | Focus | Effort | Timeline | Outcome |
|-------|-------|--------|----------|---------|
| **Phase 0** | Fix critical bugs | 1 hr | Day 1 | AWS + Azure deploy once |
| **Phase A** | Make deterministic | 4-6 hrs | Days 2-3 | Same infrastructure every time |
| **Phase B** | Multi-environment | 4-6 hrs | Days 4-5 | Works for any Azure environment |
| **Phase C** | State backend | 3-4 hrs | Days 6-7 | Safe destroy, team collaboration |
| **Optional**: CI/CD | Full automation | 6-8 hrs | Week 2 | GitHub Actions pipeline |

---

## 📁 Current Structure Issues

### ❌ Problems to Fix
1. **Random storage names** → Different every deploy
2. **Unpinned Helm versions** → Latest version breaks things
3. **Hardcoded sandbox RG** → Only works for YOUR sandbox
4. **State files in git** → Credentials exposed, can't destroy safely
5. **App Gateway disconnected** → No Kubernetes integration
6. **MongoDB misconfigured** → 1 replica instead of 3

### ✅ What's Good
- ✅ Good code organization
- ✅ Comprehensive existing docs
- ✅ AWS and Azure side-by-side

---

## 🚀 Phase 0: Fix Critical Bugs (1 Hour)

**Goal**: Get AWS + Azure working AT LEAST ONCE

### Monitoring Stack Enhancement

Add Loki and Tempo deployments to the monitoring phase:

**Files to Update**:

#### Both AWS and Azure (`*/terraform/helm.tf`)

Add after Grafana release:

```hcl
# Loki Helm Release (Log Aggregation)
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.9.3"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "loki.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "promtail.enabled"
    value = "true"
  }

  depends_on = [helm_release.grafana]
}

# Tempo Helm Release (Distributed Tracing)
resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = "1.7.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/../helm/tempo-values.yaml")
  ]

  depends_on = [helm_release.loki]
}
```

**Files to Create**:

#### AWS & Azure: `AWS/helm/tempo-values.yaml` and `AZURE/helm/tempo-values.yaml`

```yaml
# Tempo Configuration
tempo:
  enabled: true

receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:14250
  
  zipkin:
    endpoint: 0.0.0.0:9411

procesors:
  batch:
    timeout: 10s
    send_batch_size: 1024

exporters:
  otlp:
    protocols:
      grpc:
        endpoint: localhost:4317

service:
  pipelines:
    traces:
      receivers: [otlp, jaeger, zipkin]
      processors: [batch]
      exporters: [otlp]

persistence:
  enabled: true
  size: 10Gi
  storageClassName: "azure-disk"  # Change to "ebs-gp3" for AWS

resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi

service:
  type: ClusterIP
  ports:
    jaeger-compact:
      port: 6831
      protocol: UDP
    jaeger-thrift:
      port: 6832
      protocol: UDP
    jaeger-grpc:
      port: 14250
    zipkin:
      port: 9411
    otlp-grpc:
      port: 4317
    otlp-http:
      port: 4318
```

**Verification**:

```bash
# Check all monitoring components deployed
kubectl get pods -n monitoring
# Expected output includes: prometheus, grafana, loki, promtail, tempo

# Verify Grafana datasources are available
kubectl get secret grafana -n monitoring -o jsonpath='{.data.datasources\.yaml}' | base64 -d

# Test connectivity
kubectl port-forward -n monitoring svc/prometheus-server 9090:9090
kubectl port-forward -n monitoring svc/grafana 3000:3000
kubectl port-forward -n monitoring svc/loki 3100:3100
kubectl port-forward -n monitoring svc/tempo 3200:3200
```

---

**Files to Fix**:

### AWS (`AWS/terraform`)
1. **helm.tf** - Pin RocketChat version
   ```hcl
   # Line 82-85: Add version
   resource "helm_release" "rocketchat" {
     chart   = "rocketchat"
     version = "6.3.0"  # ADD THIS LINE
   ```

2. **iam.tf** - Add depends_on if missing

### Azure (`AZURE/terraform`)
1. **helm/rocketchat-values.yaml** - Fix MongoDB
   ```yaml
   # Line 22-29: Change
   replicaCount: 3  # WAS: 1
   persistence:
     enabled: true  # WAS: false
     storageClass: "azure-disk"
     size: 20Gi
   ```

2. **app_gateway.tf** - Fix health probes (lines 98-116)
   ```hcl
   # Remove: host = "127.0.0.1"
   # Add: pick_host_name_from_backend_http_settings = true
   ```

3. **storage.tf** - Fix naming collision (lines 1-6)
   ```hcl
   # Change to separate suffixes:
   resource "random_string" "files_suffix" { length = 12 }
   resource "random_string" "mongo_suffix" { length = 12 }
   # Use different names:
   name = "rcfiles${random_string.files_suffix.result}"
   name = "rcmongo${random_string.mongo_suffix.result}"
   ```

4. **helm.tf** - Pin versions + dependencies (lines 1-77)
   ```hcl
   # Add version to rocketchat (line 67)
   version = "6.3.0"
   
   # Add depends_on to kubernetes provider (line 3-6)
   depends_on = [azurerm_kubernetes_cluster.main]
   ```

**Test Phase 0**:
```bash
cd AWS/terraform && terraform init && terraform plan
cd AZURE/terraform && terraform init && terraform plan
# Both should show all resources, no errors
```

**Deliverable**: Both templates deploy without errors (infrastructure works)

---

## 🔄 Phase A: Make Deterministic (4-6 Hours)

**Goal**: Deploy → Destroy → Deploy = IDENTICAL infrastructure

**Key Changes**:
- Remove all `random_*` resources
- Pin ALL chart versions
- Add `deployment_id` variable for consistent naming
- Create version file for reproducibility

### A1: AWS Deterministic Naming

**File**: `AWS/terraform/variables.tf`

Add after line 87:
```hcl
variable "deployment_id" {
  description = "Unique deployment identifier (e.g., 'prod-001', 'sandbox-001')"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]{2,20}$", var.deployment_id))
    error_message = "deployment_id must be 2-20 lowercase alphanumeric characters"
  }
}

variable "rocketchat_version" {
  description = "RocketChat Helm chart version"
  type        = string
  default     = "6.3.0"
}

variable "prometheus_version" {
  description = "Prometheus Helm chart version"
  type        = string
  default     = "52.0.0"
}

variable "grafana_version" {
  description = "Grafana Helm chart version"
  type        = string
  default     = "6.50.0"
}
```

**File**: `AWS/terraform/terraform.tfvars`

Replace with:
```hcl
# Deployment Identifier (MUST be unique per environment)
deployment_id = "prod-001"  # Change for different deployments

# Other variables stay the same
eks_cluster_version = "1.28"
# ... etc
```

**File**: `AWS/terraform/s3.tf`

Replace random-based naming:
```hcl
# Remove: resource "random_string" "bucket_suffix"

# Replace bucket names:
resource "aws_s3_bucket" "rocketchat_files" {
  bucket = "rocketchat-${data.aws_caller_identity.current.account_id}-files-${var.deployment_id}"
  # Rest of config...
}

resource "aws_s3_bucket" "mongodb_backups" {
  bucket = "rocketchat-${data.aws_caller_identity.current.account_id}-backups-${var.deployment_id}"
  # Rest of config...
}
```

**File**: `AWS/terraform/helm.tf`

Update versions:
```hcl
resource "helm_release" "rocketchat" {
  version = var.rocketchat_version
}

resource "helm_release" "prometheus" {
  version = var.prometheus_version
}

resource "helm_release" "grafana" {
  version = var.grafana_version
}
```

### A2: Azure Deterministic Naming

**File**: `AZURE/terraform/variables.tf`

Add after line 87:
```hcl
variable "deployment_id" {
  description = "Unique deployment identifier (e.g., 'prod-001', 'sandbox-001')"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]{2,20}$", var.deployment_id))
    error_message = "deployment_id must be 2-20 lowercase alphanumeric characters"
  }
}

variable "rocketchat_version" {
  description = "RocketChat Helm chart version"
  type        = string
  default     = "6.3.0"
}

variable "prometheus_version" {
  description = "Prometheus Helm chart version"
  type        = string
  default     = "52.0.0"
}

variable "grafana_version" {
  description = "Grafana Helm chart version"
  type        = string
  default     = "6.50.0"
}
```

**File**: `AZURE/terraform/terraform.tfvars`

Replace with:
```hcl
# Deployment Identifier
deployment_id = "sandbox-001"  # Change this for different deployments

# Azure Configuration
azure_region = "East US"
project_name = "rocketchat-aks"
environment = "production"

# For sandbox (will be replaced in Phase B)
resource_group_name = "1-647774c3-playground-sandbox"

# Rest stays the same...
```

**File**: `AZURE/terraform/storage.tf`

Replace entirely:
```hcl
# No more random suffixes - use deployment_id
resource "azurerm_storage_account" "rocketchat_files" {
  name                     = "rcfiles${var.deployment_id}${substr(local.resource_group.id, -4, -1)}"
  resource_group_name      = local.resource_group.name
  location                 = local.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags
}

resource "azurerm_storage_container" "rocketchat_files" {
  name                  = "rocketchat-files"
  storage_account_name  = azurerm_storage_account.rocketchat_files.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "mongodb_backups" {
  name                     = "rcbackup${var.deployment_id}${substr(local.resource_group.id, -4, -1)}"
  resource_group_name      = local.resource_group.name
  location                 = local.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = local.common_tags
}

resource "azurerm_storage_container" "mongodb_backups" {
  name                  = "mongodb-backups"
  storage_account_name  = azurerm_storage_account.mongodb_backups.name
  container_access_type = "private"
}
```

**File**: `AZURE/terraform/helm.tf`

Update versions:
```hcl
resource "helm_release" "rocketchat" {
  version = var.rocketchat_version
}

resource "helm_release" "prometheus" {
  version = var.prometheus_version
}

resource "helm_release" "grafana" {
  version = var.grafana_version
}
```

**Test Phase A**:
```bash
# AWS
cd AWS/terraform
rm -rf .terraform terraform.tfstate*
terraform init
terraform plan -out=aws.tfplan
# Note all resource names
terraform apply aws.tfplan
terraform destroy -auto-approve

# Deploy again - verify SAME names
terraform apply -auto-approve
# Verify names match first deployment

# Azure - same process
cd AZURE/terraform
# ... same test sequence
```

**Deliverable**: Deploy → destroy → deploy = identical resource names and configuration

---

## 🌍 Phase B: Multi-Environment Support (4-6 Hours)

**Goal**: Template works for sandbox, dev, staging, prod WITHOUT manual editing

### B1: Create Environment Templates

**New Files**:

`AWS/terraform/terraform.sandbox.tfvars`:
```hcl
deployment_id = "sandbox-001"
aws_region = "us-east-1"
eks_cluster_version = "1.28"
node_count = 2
min_count = 2
max_count = 3
# ... rest of config
```

`AWS/terraform/terraform.dev.tfvars`:
```hcl
deployment_id = "dev-001"
aws_region = "us-east-1"
eks_cluster_version = "1.28"
node_count = 2
min_count = 1
max_count = 2
# ... rest
```

`AWS/terraform/terraform.prod.tfvars`:
```hcl
deployment_id = "prod-001"
aws_region = "us-east-1"
eks_cluster_version = "1.28"
node_count = 3
min_count = 3
max_count = 5
# ... rest with production settings
```

Same for Azure:

`AZURE/terraform/terraform.sandbox.tfvars`:
```hcl
deployment_id = "sandbox-001"
resource_group_name = "1-647774c3-playground-sandbox"
azure_region = "East US"
aks_cluster_version = "1.31.11"
node_count = 2
min_count = 2
max_count = 3
```

`AZURE/terraform/terraform.dev.tfvars`:
```hcl
deployment_id = "dev-001"
resource_group_name = "rocketchat-dev-rg"
azure_region = "East US"
aks_cluster_version = "1.31.11"
node_count = 2
min_count = 1
max_count = 2
```

`AZURE/terraform/terraform.prod.tfvars`:
```hcl
deployment_id = "prod-001"
resource_group_name = "rocketchat-prod-rg"
azure_region = "East US"
aks_cluster_version = "1.31.11"
node_count = 3
min_count = 3
max_count = 5
```

### B2: Update Main tfvars

**File**: `AWS/terraform/terraform.tfvars`

Add comment at top:
```hcl
# Use environment-specific files:
# terraform apply -var-file=terraform.sandbox.tfvars
# terraform apply -var-file=terraform.dev.tfvars
# terraform apply -var-file=terraform.prod.tfvars

# This file kept for reference/defaults
```

Same for Azure.

### B3: Update Deployment Documentation

**File**: `DOCs/deployment.md` - Update Azure section with:

```bash
# For different environments:
cd AZURE/terraform

# Sandbox
terraform apply -var-file=terraform.sandbox.tfvars

# Dev
terraform apply -var-file=terraform.dev.tfvars

# Production
terraform apply -var-file=terraform.prod.tfvars
```

**Test Phase B**:
```bash
# Test AWS across environments
cd AWS/terraform

# Deploy to sandbox
terraform init
terraform apply -var-file=terraform.sandbox.tfvars -auto-approve
# Verify: rocketchat-sandbox-001 resources

terraform destroy -var-file=terraform.sandbox.tfvars -auto-approve

# Deploy to dev
terraform apply -var-file=terraform.dev.tfvars -auto-approve
# Verify: rocketchat-dev-001 resources

terraform destroy -var-file=terraform.dev.tfvars -auto-approve

# Same for Azure with different RGs
```

**Deliverable**: Deploy to sandbox/dev/prod by just changing the tfvars file

---

## 🔐 Phase C: Remote State Backend (3-4 Hours)

**Goal**: Safe destroy, team collaboration, prevent state loss

### C1: Setup State Storage (Azure)

```bash
# Create state management resources (one-time)
az group create -n terraform-state -l eastus

az storage account create \
  --name tfstatexxxxxx \  # Must be globally unique
  --resource-group terraform-state \
  --location eastus \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name tfstatexxxxxx

# Enable versioning
az storage account blob-service-properties update \
  --account-name tfstatexxxxxx \
  --enable-versioning
```

### C2: AWS Terraform Backend

**File**: `AWS/terraform/versions.tf`

Add after line 21:
```hcl
  backend "s3" {
    bucket         = "terraform-state-ACCOUNT-ID"
    key            = "rocketchat/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**Setup (one-time)**:
```bash
# Create state bucket and lock table
aws s3 mb s3://terraform-state-$(aws sts get-caller-identity --query Account -o text) --region us-east-1

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### C3: Azure Terraform Backend

**File**: `AZURE/terraform/versions.tf`

Replace with:
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-state"
    storage_account_name = "tfstatexxxxxx"
    container_name       = "tfstate"
    key                  = "rocketchat/${var.environment}.tfstate"
  }
}
```

### C4: Remove State from Git

**File**: `.gitignore`

Add:
```
# Terraform
terraform.tfstate
terraform.tfstate.*
.terraform/
*.tfplan
*.tfstate.backup
```

### C5: Migrate State

```bash
# AWS
cd AWS/terraform
terraform init  # Will prompt to migrate
# Type 'yes' to migrate

# Azure
cd AZURE/terraform
terraform init  # Will prompt to migrate
# Type 'yes' to migrate
```

**Test Phase C**:
```bash
# AWS
cd AWS/terraform
terraform destroy -var-file=terraform.sandbox.tfvars
# Verify: all resources destroyed, state maintained in S3

terraform apply -var-file=terraform.sandbox.tfvars
# Verify: recreated same resources
terraform destroy -var-file=terraform.sandbox.tfvars

# Azure - same process
```

**Deliverable**: State managed remotely, safe destroy, team-ready

---

## 🌐 Phase D: Production Deployment with Domain & SSL (6-8 Hours)

**Goal**: Deploy production-ready RocketChat with custom domain, SSL, monitoring alerts, and automated backups

**Prerequisites**: Phases A, B, C complete

### D1: Domain & DNS Configuration

**Option A: Azure DNS Zone** (Recommended)

**File**: `AZURE/terraform/dns.tf` (new)

```hcl
resource "azurerm_dns_zone" "main" {
  name                = var.domain_name  # "yourdomain.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_dns_a_record" "rocketchat" {
  name                = var.subdomain  # "chat"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_public_ip.app_gateway.ip_address]
}

output "dns_nameservers" {
  value = azurerm_dns_zone.main.name_servers
  description = "Update these at your domain registrar"
}
```

**Manual Step**: Update nameservers at your domain registrar with Azure DNS values.

### D2: SSL Certificate with Let's Encrypt

**File**: `AZURE/terraform/ssl.tf` (new)

```hcl
# cert-manager for Let's Encrypt
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.2"
  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

# Let's Encrypt ClusterIssuer
resource "kubernetes_manifest" "letsencrypt_prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata   = { name = "letsencrypt-prod" }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = { name = "letsencrypt-prod" }
        solvers = [{
          http01 = { ingress = { class = "nginx" } }
        }]
      }
    }
  }
  depends_on = [helm_release.cert_manager]
}
```

### D3: Azure Key Vault for Secrets

**File**: `AZURE/terraform/keyvault.tf` (new)

```hcl
resource "azurerm_key_vault" "main" {
  name                = "${var.deployment_id}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  purge_protection_enabled = true
  
  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "mongodb_password" {
  name         = "mongodb-admin-password"
  value        = random_password.mongodb.result
  key_vault_id = azurerm_key_vault.main.id
}
```

### D4: Production Monitoring Alerts

**File**: `AZURE/terraform/monitoring-alerts.tf` (new)

```hcl
resource "azurerm_monitor_action_group" "main" {
  name                = "${var.deployment_id}-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = var.deployment_id

  email_receiver {
    name          = "DevOps Team"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "${var.deployment_id}-high-cpu"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_kubernetes_cluster.main.id]
  description         = "Alert when CPU > 80%"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Additional alerts: memory, pod restarts, app gateway health
```

### D5: Automated MongoDB Backups

**File**: `AZURE/terraform/backup.tf` (new)

```hcl
resource "kubernetes_cron_job_v1" "mongodb_backup" {
  metadata {
    name      = "mongodb-backup"
    namespace = "rocketchat"
  }

  spec {
    schedule = "0 2 * * *"  # 2 AM daily

    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            container {
              name  = "mongodb-backup"
              image = "mongo:6.0"
              command = ["/bin/sh", "-c"]
              args = [
                "mongodump --host=rocketchat-mongodb:27017 --out=/backup/$(date +%Y%m%d) && az storage blob upload-batch --account-name ${var.storage_account} --destination mongodb-backups --source /backup/"
              ]
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}
```

### D6: Production RocketChat Values

**File**: `AZURE/helm/rocketchat-values-prod.yaml` (new)

```yaml
replicaCount: 3  # High availability

image:
  tag: "7.11.0"  # Current stable version

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: chat.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: rocketchat-tls
      hosts:
        - chat.yourdomain.com

mongodb:
  replicaCount: 3
  persistence:
    storageClass: "managed-premium"
    size: 100Gi
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi

env:
  - name: ROOT_URL
    value: "https://chat.yourdomain.com"

resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    cpu: 2000m
    memory: 4Gi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### D7: Update Production Variables

**File**: `AZURE/terraform/variables.tf` (add new variables)

```hcl
variable "domain_name" {
  description = "Domain name for RocketChat"
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain for RocketChat (e.g., 'chat')"
  type        = string
  default     = "chat"
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate notifications"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email for Azure Monitor alerts"
  type        = string
  default     = ""
}
```

### D8: Update Production tfvars

**File**: `AZURE/terraform/terraform.prod.tfvars` (add to existing)

```hcl
# Domain & SSL (NEW)
domain_name       = "yourdomain.com"
subdomain         = "chat"
letsencrypt_email = "devops@yourdomain.com"

# Monitoring (NEW)
alert_email = "alerts@yourdomain.com"

# Updated Production Sizing
node_vm_size  = "Standard_D4s_v3"  # 4 vCPU, 16GB RAM
node_count    = 5
min_count     = 3
max_count     = 10

# Storage (Premium for production)
storage_account_tier = "Premium"
storage_replication  = "ZRS"
```

### D9: Version Management

**Always use current versions** - see `DOCs/VERSION-MANAGEMENT.md` for checking latest:

```bash
# Check current RocketChat version
helm search repo rocketchat/rocketchat --versions | head -5

# Update in helm values files
image:
  tag: "7.11.0"  # Not 7.0.0!
```

**Test Phase D**:
```bash
cd AZURE/terraform

# Deploy to production
terraform plan -var-file=terraform.prod.tfvars -out=prod.tfplan
terraform apply prod.tfplan

# Verify
kubectl get certificate -n rocketchat
curl -I https://chat.yourdomain.com
```

**Validation Checklist**:
- [ ] Domain resolves to App Gateway IP
- [ ] SSL certificate issued by Let's Encrypt
- [ ] HTTPS redirect working
- [ ] RocketChat accessible at https://chat.yourdomain.com
- [ ] 3 RocketChat replicas running
- [ ] MongoDB HA operational
- [ ] Monitoring alerts configured
- [ ] Backup CronJob running
- [ ] All pods healthy

**Deliverable**: Production RocketChat with custom domain, SSL, alerts, and backups

**Estimated Production Cost**: ~$1,160/month (5 x D4s_v3 nodes, App Gateway WAF, Premium storage)

---

## 📋 Implementation Checklist

### Phase 0 (1 hour)
- [ ] AWS: Pin Helm chart versions
- [ ] Azure: Fix MongoDB replicas
- [ ] Azure: Fix App Gateway probes
- [ ] Azure: Fix storage naming
- [ ] Azure: Add provider depends_on
- [ ] Verify both: `terraform plan` succeeds
- [ ] Test AWS: Deploy and destroy work
- [ ] Test Azure: Deploy and destroy work

### Phase A (4-6 hours)
- [ ] AWS: Add deployment_id + version variables
- [ ] AWS: Update s3.tf with deterministic naming
- [ ] AWS: Update helm.tf with versions
- [ ] Azure: Add deployment_id + version variables
- [ ] Azure: Rewrite storage.tf without random
- [ ] Azure: Update helm.tf with versions
- [ ] Test AWS: Deploy → Destroy → Deploy = same names
- [ ] Test Azure: Deploy → Destroy → Deploy = same names
- [ ] **Validate monitoring stack**: Prometheus, Grafana, Loki, Tempo healthy (see troubleshooting-azure.md § 9 for Loki issues)

### Phase B (4-6 hours)
- [ ] AWS: Create terraform.sandbox/dev/prod.tfvars
- [ ] Azure: Create terraform.sandbox/dev/prod.tfvars
- [ ] Update deployment.md with environment examples
- [ ] Test AWS: Deploy each environment separately
- [ ] Test Azure: Deploy each environment separately
- [ ] Verify each environment has correct naming

### Phase C (3-4 hours)
- [ ] AWS: Create S3 bucket + DynamoDB table
- [ ] Azure: Create state RG + storage account
- [ ] AWS: Add backend block to versions.tf
- [ ] Azure: Add backend block to versions.tf
- [ ] Migrate both: `terraform init` to remote backend
- [ ] Update .gitignore
- [ ] Test destroy/recreate with remote state
- [ ] Remove old local state files

### Phase D (6-8 hours) - Production with Domain & SSL
- [ ] Register domain or prepare existing domain
- [ ] Azure: Create dns.tf with DNS zone
- [ ] Azure: Create ssl.tf with cert-manager
- [ ] Azure: Create keyvault.tf for secrets
- [ ] Azure: Create monitoring-alerts.tf
- [ ] Azure: Create backup.tf for MongoDB backups
- [ ] Create rocketchat-values-prod.yaml with SSL config
- [ ] Update terraform.prod.tfvars with domain/email
- [ ] Update RocketChat version to 7.11.0 (not 7.0.0!)
- [ ] Deploy to production subscription
- [ ] Verify SSL certificate issued
- [ ] Test https://chat.yourdomain.com
- [ ] Verify monitoring alerts
- [ ] Test MongoDB backups

---

## 📊 Daily Workflow After Implementation

### Deploy to Sandbox
```bash
cd AZURE/terraform
terraform apply -var-file=terraform.sandbox.tfvars
```

### Deploy to Dev
```bash
cd AZURE/terraform
terraform apply -var-file=terraform.dev.tfvars
```

### Destroy (any environment)
```bash
cd AZURE/terraform
terraform destroy -var-file=terraform.sandbox.tfvars
```

### Redeploy (same environment)
```bash
cd AZURE/terraform
terraform apply -var-file=terraform.sandbox.tfvars
# ← Same infrastructure recreated
```

---

## 🎯 Success Criteria

✅ **Phase 0 Complete**: AWS + Azure deploy without errors  
✅ **Phase A Complete**: Deploy → Destroy → Deploy produces identical infrastructure  
✅ **Phase B Complete**: Can deploy to any environment with one command  
✅ **Phase C Complete**: Team members can destroy/deploy safely with remote state  
✅ **Phase D Complete**: Production deployment with custom domain, SSL, alerts, and backups  
✅ **All Phases Complete**: Production-ready template with full observability and automation

---

## 📂 Files Modified Summary

### Phase 0
- AWS: helm.tf
- Azure: helm/rocketchat-values.yaml, app_gateway.tf, storage.tf, helm.tf

### Phase A
- AWS: variables.tf, s3.tf, helm.tf, terraform.tfvars
- Azure: variables.tf, storage.tf, helm.tf, terraform.tfvars

### Phase B
- AWS: terraform.sandbox/dev/prod.tfvars (new)
- Azure: terraform.sandbox/dev/prod.tfvars (new)
- DOCs: deployment.md (update)

### Phase C
- AWS: versions.tf
- Azure: versions.tf
- Root: .gitignore

### Phase D
- Azure: dns.tf, ssl.tf, keyvault.tf, monitoring-alerts.tf, backup.tf (new)
- Azure: terraform.prod.tfvars (update), variables.tf (add domain/email vars)
- Azure: helm/rocketchat-values-prod.yaml (new)
- DOCs: VERSION-MANAGEMENT.md (reference)

---

## 🚀 Ready to Start?

**Proceed to Phase 0** and fix the critical bugs first in Cursor.

Then work through Phases A → B → C sequentially.

**Estimated total time**: 3 weeks (includes production deployment)

---

**Master Plan Version**: 2.0  
**Last Updated**: October 24, 2025  
**Status**: Phase B Complete | Phase C & D Ready
