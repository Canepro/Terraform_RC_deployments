# Random string for unique storage account names - FILES
resource "random_string" "files_suffix" {
  length  = 12
  special = false
  upper   = false
}

# Random string for unique storage account names - MONGODB
resource "random_string" "mongo_suffix" {
  length  = 12
  special = false
  upper   = false
}

# Storage Account for RocketChat files
resource "azurerm_storage_account" "rocketchat_files" {
  name                     = "rcfiles${random_string.files_suffix.result}"
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
  name                     = "rcmongo${random_string.mongo_suffix.result}"
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
