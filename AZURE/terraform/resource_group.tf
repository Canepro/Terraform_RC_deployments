# Resource Group (conditional creation)
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.azure_region

  tags = local.common_tags
}

# Data source for existing resource group (when not creating new one)
data "azurerm_resource_group" "main" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

# Local reference to the resource group (either created or existing)
locals {
  resource_group = var.create_resource_group ? azurerm_resource_group.main[0] : data.azurerm_resource_group.main[0]
}
