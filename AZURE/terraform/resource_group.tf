# Data source to discover sandbox resource group automatically
data "azurerm_resources" "sandbox_rg" {
  count = var.create_resource_group ? 0 : 1
  type  = "Microsoft.Resources/resourceGroups"

  # Find sandbox RG by pattern (e.g., "1-*-playground-sandbox")
  required_tags = {}
}

# Resource Group (conditional creation)
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = local.resource_group_name
  location = var.azure_region

  tags = local.common_tags
}

# Data source for existing resource group (when not creating new one)
data "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 0 : 1
  # Auto-discover sandbox RG or use explicit name
  name  = var.resource_group_name != "" ? var.resource_group_name : try(
    [for rg in data.azurerm_resources.sandbox_rg[0].resources : rg.name if can(regex(".*playground-sandbox$", rg.name))][0],
    "rocketchat-rg"  # fallback
  )
}

# Local reference to the resource group (either created or existing)
locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.main[0] : data.azurerm_resource_group.main[0]
}
