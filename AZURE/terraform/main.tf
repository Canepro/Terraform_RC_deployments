# Configure the Azure Provider
provider "azurerm" {
  features {}
  
  # Disable automatic resource provider registration for sandbox environments
  skip_provider_registration = true
}

# Data source for current Azure client
data "azurerm_client_config" "current" {}

# Local values for common configurations
locals {
  name = "${var.project_name}-${var.environment}"
  
  # Deterministic naming based on deployment_id
  deployment_id_sanitized = lower(replace(var.deployment_id, "/[^a-z0-9]/", ""))
  
  # Azure storage account names (3-24 chars, lowercase alphanumeric only)
  storage_files_name = substr("${local.deployment_id_sanitized}rcfiles", 0, 24)
  storage_mongo_name = substr("${local.deployment_id_sanitized}rcmongo", 0, 24)
  
  # AKS cluster name
  aks_cluster_name = "${local.deployment_id_sanitized}-aks"
  
  # Resource group name
  resource_group_name = "${local.deployment_id_sanitized}-rg"
  
  common_tags = merge(var.tags, {
    Name         = local.name
    DeploymentID = var.deployment_id
  })
}
