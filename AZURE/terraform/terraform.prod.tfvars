# ========================================
# Azure Production Environment Configuration
# ========================================
# Usage: terraform apply -var-file=terraform.prod.tfvars

# Deployment Identifier (REQUIRED - must be unique per deployment)
deployment_id = "prod-001"

# Azure Configuration
azure_region = "East US"
project_name = "rocketchat-aks"
environment  = "production"

# Production Resource Group (requires creation)
resource_group_name   = "rocketchat-prod-rg"
create_resource_group = true

# Network Configuration
vnet_cidr = "10.0.0.0/16"

# AKS Configuration - Production sizing (full resources)
aks_cluster_version = "1.31"
node_vm_size        = "Standard_D2s_v3"  # Production-grade VMs
node_count          = 3
min_count           = 3  # Maintain minimum availability
max_count           = 6  # Allow scaling for high load

# RocketChat Configuration - Full redundancy
rocketchat_replicas = 3  # High availability
mongodb_replicas    = 3  # Replica set

# Tags
tags = {
  Project      = "RocketChat"
  Environment  = "Production"
  ManagedBy    = "Terraform"
  DeploymentID = "prod-001"
}

