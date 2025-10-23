# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = local.name
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  dns_prefix          = local.name
  kubernetes_version  = var.aks_cluster_version

  default_node_pool {
    name                = "default"
    node_count         = var.node_count
    vm_size            = var.node_vm_size
    vnet_subnet_id     = azurerm_subnet.aks_nodes.id
    enable_auto_scaling = true
    min_count          = var.min_count
    max_count          = var.max_count
    os_disk_size_gb    = 30
    type               = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  # Enable monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  tags = local.common_tags
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.name}-logs"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}
