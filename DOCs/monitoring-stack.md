# Complete Monitoring Stack Guide (Prometheus, Grafana, Loki, Tempo)

**AWS EKS & Azure AKS**

This guide covers the complete observability stack with metrics, logs, and traces.

---

## 📊 Monitoring Stack Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Observability Stack                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Prometheus   │  │    Loki      │  │    Tempo     │       │
│  │  (Metrics)   │  │  (Logs)      │  │  (Traces)    │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│         │                  │                  │               │
│         └──────────────────┼──────────────────┘               │
│                            │                                  │
│                    ┌───────▼────────┐                        │
│                    │    Grafana     │                        │
│                    │  (Dashboards)  │                        │
│                    └────────────────┘                        │
│                                                               │
└─────────────────────────────────────────────────────────────┘

From Applications:
  RocketChat → Prometheus Exporter → Prometheus
  RocketChat → Promtail Agent → Loki
  RocketChat → OTLP Collector → Tempo
```

---

## 🎯 Components

### 1. Prometheus (Metrics Collection)
- **Port**: 9090
- **Function**: Time-series metrics database
- **Data Retention**: 15 days default
- **Scrapers**:
  - Kubernetes metrics (kubelet, nodes)
  - Node exporter (system metrics)
  - Application metrics (RocketChat)

### 2. Loki (Log Aggregation)
- **Port**: 3100
- **Function**: Log storage and querying
- **Storage**: Multi-day retention (configurable)
- **Scrapers**:
  - Promtail agents (pod logs)
  - Syslog integration (optional)

### 3. Tempo (Distributed Tracing)
- **Port**: 3200
- **Function**: Distributed trace storage
- **Receivers**: OTLP, Jaeger, Zipkin compatible
- **Integration**: Traces from RocketChat and services

### 4. Grafana (Visualization)
- **Port**: 3000
- **Function**: Dashboards and alerting
- **Datasources**: Prometheus, Loki, Tempo
- **Features**: Cross-datasource queries, alerting rules

---

## 🚀 Deployment

### Via Terraform (Recommended)

**Add to `helm.tf` for both AWS and Azure:**

```hcl
# Loki Helm Release
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.9.3"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "loki.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "promtail.enabled"
    value = "true"
  }

  depends_on = [
    azurerm_kubernetes_cluster.main,
    kubernetes_storage_class.azure_disk
  ]
}

# Tempo Helm Release
resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = "1.7.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/../helm/tempo-values.yaml")
  ]

  depends_on = [
    azurerm_kubernetes_cluster.main,
    kubernetes_storage_class.azure_disk
  ]
}
```

**Note**: Update `kubernetes_namespace.monitoring` to `null_resource` or use appropriate reference for AWS.

---

## 📁 Helm Values Files

### tempo-values.yaml (New file for both AWS & Azure)

**Create `AWS/helm/tempo-values.yaml` and `AZURE/helm/tempo-values.yaml`:**

```yaml
# Tempo Configuration
tempo:
  enabled: true
  
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:14250
  
  zipkin:
    endpoint: 0.0.0.0:9411

procesors:
  batch:
    timeout: 10s
    send_batch_size: 1024

exporters:
  otlp:
    protocols:
      grpc:
        endpoint: localhost:4317

service:
  pipelines:
    traces:
      receivers: [otlp, jaeger, zipkin]
      processors: [batch]
      exporters: [otlp]

persistence:
  enabled: true
  size: 10Gi
  # AWS: storageClassName: ebs-gp3
  # Azure: storageClassName: azure-disk

resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi

# Service configuration
service:
  type: ClusterIP
  ports:
    jaeger-compact:
      port: 6831
      protocol: UDP
    jaeger-thrift:
      port: 6832
      protocol: UDP
    jaeger-grpc:
      port: 14250
    zipkin:
      port: 9411
    otlp-grpc:
      port: 4317
    otlp-http:
      port: 4318
```

---

## 🔗 Data Flow Integration

### Application → Prometheus (Metrics)
```yaml
# In RocketChat Helm values
metrics:
  enabled: true
  prometheus:
    monitor:
      enabled: true
      interval: 30s
```

### Application → Loki (Logs)
```yaml
# Configure Promtail in loki-stack chart
promtail:
  enabled: true
  config:
    scrape_configs:
      - job_name: rocketchat
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace
```

### Application → Tempo (Traces)
```yaml
# In RocketChat environment variables
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://tempo:4317"
  - name: OTEL_SDK_DISABLED
    value: "false"
```

---

## 📊 Grafana Configuration

### Datasources (Pre-configured)

All three datasources are pre-configured in `grafana-values.yaml`:

```yaml
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus-server:9090
    isDefault: true
  
  - name: Loki
    type: loki
    url: http://loki:3100
  
  - name: Tempo
    type: tempo
    url: http://tempo:3200
```

### Dashboard Examples

**Metrics Dashboard (Prometheus)**
- RocketChat Performance (ID: 23428)
- RocketChat Microservices (ID: 23427)
- Node Exporter Full (ID: 1860)

**Logs Dashboard (Loki)**
```query
{job="rocketchat"} | json | level="ERROR"
```

**Traces Dashboard (Tempo)**
- Service Graph: Shows all services and dependencies
- Request Timeline: Visualize request flow across services

---

## 🔍 Querying Data

### Prometheus (Metrics)

```promql
# CPU usage
rate(container_cpu_usage_seconds_total{pod=~"rocketchat.*"}[5m]) * 100

# Memory usage
container_memory_usage_bytes{pod=~"rocketchat.*"} / 1024 / 1024

# Request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
```

### Loki (Logs)

```logql
# All RocketChat logs
{pod="rocketchat"}

# ERROR logs
{pod="rocketchat"} | json | level="ERROR"

# Logs with specific user
{pod="rocketchat"} | json | user="admin"

# Request latency
{pod="rocketchat"} | json | latency > 1000
```

### Tempo (Traces)

- **Service Map**: View service dependencies
- **Trace Search**: Find traces by service, span name, status
- **Latency Analysis**: Identify slow operations
- **Error Analysis**: View failed requests and error traces

---

## 🚨 Alerting Setup

### Prometheus Alert Rules

Create `monitoring-alerts.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: rocketchat-alerts
  namespace: monitoring
spec:
  groups:
  - name: rocketchat
    interval: 30s
    rules:
    - alert: RocketChatDown
      expr: up{job="rocketchat"} == 0
      for: 5m
      annotations:
        summary: "RocketChat is down"
    
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 5m
      annotations:
        summary: "High error rate detected"
    
    - alert: HighMemoryUsage
      expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.9
      for: 5m
      annotations:
        summary: "High memory usage"
```

---

## 🔄 Data Retention

| Component | Retention | Storage | Cost Impact |
|-----------|-----------|---------|------------|
| **Prometheus** | 15 days | 20GB | High |
| **Loki** | 30 days | 10GB | Low |
| **Tempo** | 7 days | 10GB | Medium |
| **Grafana** | N/A | 10GB | Low |

---

## 🎯 Access Points

### Local Development
```bash
# Port-forward to access locally
kubectl port-forward -n monitoring svc/prometheus-server 9090:9090
kubectl port-forward -n monitoring svc/loki 3100:3100
kubectl port-forward -n monitoring svc/tempo 3200:3200
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Then access:
# Prometheus: http://localhost:9090
# Loki: http://localhost:3100
# Tempo: http://localhost:3200
# Grafana: http://localhost:3000
```

### Production (via Load Balancer)
```bash
# Get Grafana endpoint
kubectl get ingress -n monitoring

# Or directly via service
kubectl get svc -n monitoring
```

---

## 🛠️ Troubleshooting

### Prometheus not scraping metrics
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
kubectl get prometheus -n monitoring
```

### Loki not collecting logs
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail
kubectl get daemonsets -n monitoring
```

### Tempo not receiving traces
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=tempo
# Check OTLP endpoints are reachable
kubectl exec -n rocketchat <pod> -- nc -zv tempo 4317
```

### Grafana datasource connection issues
```bash
# Check from Grafana pod
kubectl exec -n monitoring <grafana-pod> -- curl http://prometheus-server:9090
kubectl exec -n monitoring <grafana-pod> -- curl http://loki:3100
kubectl exec -n monitoring <grafana-pod> -- curl http://tempo:3200
```

---

## 📚 Documentation

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Tempo Documentation](https://grafana.com/docs/tempo/latest/)
- [Grafana Documentation](https://grafana.com/docs/grafana/)

---

**Last Updated**: October 23, 2025  
**Platforms**: AWS EKS & Azure AKS  
**Status**: Comprehensive observability stack guide
