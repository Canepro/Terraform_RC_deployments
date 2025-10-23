# Configure Kubernetes Provider
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# Configure Helm Provider
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# Get EKS cluster auth token
data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

# Add Prometheus Helm Repository
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "52.0.0"
  create_namespace = true

  values = [
    file("${path.module}/../helm/prometheus-values.yaml")
  ]

  depends_on = [aws_eks_node_group.main]
}

# Add Grafana Helm Repository
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring"
  version    = "6.50.0"
  create_namespace = true

  values = [
    file("${path.module}/../helm/grafana-values.yaml")
  ]

  depends_on = [helm_release.prometheus]
}

# Loki Helm Release (Log Aggregation)
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = "monitoring"

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "10Gi"
  }

  set {
    name  = "persistence.storageClassName"
    value = "ebs-gp3"
  }

  depends_on = [helm_release.grafana]
}

# Tempo Helm Release (Distributed Tracing)
resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  namespace  = "monitoring"

  values = [
    file("${path.module}/../helm/tempo-values.yaml")
  ]

  depends_on = [helm_release.loki]
}

# Add AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.5.4"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [aws_eks_node_group.main]
}

# Add RocketChat Helm Chart
resource "helm_release" "rocketchat" {
  name       = "rocketchat"
  repository = "https://rocketchat.github.io/helm-charts"
  chart      = "rocketchat"
  namespace  = "rocketchat"
  create_namespace = true

  values = [
    file("${path.module}/../helm/rocketchat-values.yaml")
  ]

  depends_on = [
    aws_eks_node_group.main,
    helm_release.aws_load_balancer_controller
  ]
}
