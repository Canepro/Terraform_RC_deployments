# ========================================
# Azure Development Environment Configuration
# ========================================
# Usage: terraform apply -var-file=terraform.dev.tfvars

# Deployment Identifier (REQUIRED - must be unique per deployment)
deployment_id = "dev-001"

# Azure Configuration
azure_region = "East US"
project_name = "rocketchat-aks"
environment  = "development"

# Development Resource Group (requires creation)
resource_group_name   = "rocketchat-dev-rg"
create_resource_group = true

# Network Configuration
vnet_cidr = "10.0.0.0/16"

# AKS Configuration - Dev sizing (moderate resources)
aks_cluster_version = "1.31"
node_vm_size        = "Standard_B2ms"
node_count          = 2
min_count           = 1  # Can scale down to save costs
max_count           = 3

# RocketChat Configuration
rocketchat_replicas = 2
mongodb_replicas    = 3

# Tags
tags = {
  Project      = "RocketChat"
  Environment  = "Development"
  ManagedBy    = "Terraform"
  DeploymentID = "dev-001"
}

