# ========================================
# Azure Sandbox Environment Configuration
# ========================================
# Usage: terraform apply -var-file=terraform.sandbox.tfvars

# Deployment Identifier (REQUIRED - must be unique per deployment)
deployment_id = "sandbox01"

# Azure Configuration
azure_region = "East US"
project_name = "rocketchat-aks"
environment  = "sandbox"

# Sandbox Resource Group (from Learn Sandbox)
resource_group_name   = "1-56cc724a-playground-sandbox"
create_resource_group = false  # Use existing sandbox RG

# Network Configuration
vnet_cidr = "10.0.0.0/16"

# AKS Configuration - Sandbox sizing (minimal resources)
aks_cluster_version = "1.31"
node_vm_size        = "Standard_B2s"  # Minimal size for sandbox
node_count          = 2
min_count           = 2
max_count           = 3  # Limited scaling for sandbox

# RocketChat Configuration - Minimal replicas
rocketchat_replicas = 1  # Single replica for sandbox
mongodb_replicas    = 1  # Single replica for sandbox

# Tags
tags = {
  Project      = "RocketChat"
  Environment  = "Sandbox"
  ManagedBy    = "Terraform"
  DeploymentID = "sandbox01"
}

