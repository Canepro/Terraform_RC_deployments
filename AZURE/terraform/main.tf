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
  
  common_tags = merge(var.tags, {
    Name = local.name
  })
}
