# Data source to discover all resource groups (for auto-discovery)
data "azurerm_resources" "all_rgs" {
  count = var.create_resource_group ? 0 : 1
  type  = "Microsoft.Resources/resourceGroups"
}

# Local to auto-discover sandbox RG name
locals {
  # Find first RG matching "*playground-sandbox" pattern
  discovered_rg_name = var.create_resource_group ? "" : try(
    [for rg in data.azurerm_resources.all_rgs[0].resources : rg.name if can(regex(".*playground-sandbox$", rg.name))][0],
    ""
  )
  
  # Use explicit name, or discovered name, or fail with helpful error
  resolved_rg_name = var.resource_group_name != "" ? var.resource_group_name : local.discovered_rg_name
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
  name  = local.resolved_rg_name

  lifecycle {
    precondition {
      condition     = local.resolved_rg_name != ""
      error_message = "Could not auto-discover sandbox resource group. Please set resource_group_name in terraform.tfvars to your sandbox RG name (e.g., '1-bb26fa15-playground-sandbox')."
    }
  }
}

# Local reference to the resource group (either created or existing)
locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.main[0] : data.azurerm_resource_group.main[0]
}
