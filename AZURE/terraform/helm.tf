# Configure Kubernetes provider
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key            = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
    client_key            = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  }
}

# Kubernetes namespaces
resource "kubernetes_namespace" "rocketchat" {
  metadata {
    name = "rocketchat"
    labels = {
      name = "rocketchat"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

# Storage Classes for Azure
resource "kubernetes_storage_class" "azure_disk" {
  metadata {
    name = "azure-disk"
  }
  storage_provisioner = "disk.csi.azure.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    skuname = "Premium_LRS"
  }
}

resource "kubernetes_storage_class" "azure_file" {
  metadata {
    name = "azure-file"
  }
  storage_provisioner = "file.csi.azure.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"
  parameters = {
    skuName = "Standard_LRS"
  }
}

# RocketChat Helm Release
resource "helm_release" "rocketchat" {
  name       = "rocketchat"
  repository = "https://rocketchat.github.io/helm-charts"
  chart      = "rocketchat"
  version    = "8.0.0"
  namespace  = kubernetes_namespace.rocketchat.metadata[0].name

  values = [
    file("${path.module}/../helm/rocketchat-values.yaml")
  ]

  depends_on = [
    azurerm_kubernetes_cluster.main,
    kubernetes_storage_class.azure_disk
  ]
}

# Prometheus Helm Release
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "52.0.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/../helm/prometheus-values.yaml")
  ]

  depends_on = [
    azurerm_kubernetes_cluster.main,
    kubernetes_storage_class.azure_disk
  ]
}

# Grafana Helm Release
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.50.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/../helm/grafana-values.yaml")
  ]

  depends_on = [
    azurerm_kubernetes_cluster.main,
    helm_release.prometheus
  ]
}

# Loki Helm Release (Log Aggregation)
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.20.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/../helm/loki-values.yaml")
  ]

  depends_on = [helm_release.grafana]
}

# Tempo Helm Release (Distributed Tracing)
resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = "1.10.5"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/../helm/tempo-values.yaml")
  ]

  depends_on = [helm_release.loki]
}