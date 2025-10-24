# Storage Account for RocketChat files
resource "azurerm_storage_account" "rocketchat_files" {
  name                     = local.storage_files_name
  resource_group_name      = local.resource_group.name
  location                = local.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind            = "StorageV2"

  # Enable versioning
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags
}

# Storage Container for RocketChat files
resource "azurerm_storage_container" "rocketchat_files" {
  name                  = "rocketchat-files"
  storage_account_name  = azurerm_storage_account.rocketchat_files.name
  container_access_type = "private"
}

# Storage Account for MongoDB backups
resource "azurerm_storage_account" "mongodb_backups" {
  name                     = local.storage_mongo_name
  resource_group_name      = local.resource_group.name
  location                = local.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind            = "StorageV2"

  tags = local.common_tags
}

# Storage Container for MongoDB backups
resource "azurerm_storage_container" "mongodb_backups" {
  name                  = "mongodb-backups"
  storage_account_name  = azurerm_storage_account.mongodb_backups.name
  container_access_type = "private"
}
