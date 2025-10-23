# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = local.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = local.resource_group.id
}

# VNet Outputs
output "vnet_id" {
  description = "ID of the VNet"
  value       = azurerm_virtual_network.main.id
}

output "vnet_cidr_block" {
  description = "CIDR block of the VNet"
  value       = azurerm_virtual_network.main.address_space[0]
}

# AKS Outputs
output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "aks_cluster_private_fqdn" {
  description = "AKS cluster private FQDN"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

# Application Gateway Outputs
output "app_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "app_gateway_fqdn" {
  description = "FQDN of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.fqdn
}

# Storage Outputs
output "storage_account_name" {
  description = "Name of the storage account for RocketChat files"
  value       = azurerm_storage_account.rocketchat_files.name
}

output "storage_account_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = azurerm_storage_account.rocketchat_files.primary_blob_endpoint
}

# Access Information
output "kubectl_config" {
  description = "Kubectl config command"
  value       = "az aks get-credentials --resource-group ${local.resource_group.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "rocketchat_url" {
  description = "RocketChat application URL"
  value       = "http://${azurerm_public_ip.app_gateway.ip_address}"
}

output "grafana_url" {
  description = "Grafana monitoring URL"
  value       = "http://${azurerm_public_ip.app_gateway.ip_address}/grafana"
}
