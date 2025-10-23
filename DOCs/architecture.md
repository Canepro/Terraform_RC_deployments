# RocketChat Kubernetes Architecture (AWS EKS & Azure AKS)

## Overview

This deployment creates production-ready RocketChat instances on **both AWS EKS and Azure AKS** with comprehensive monitoring and observability. Both architectures follow the same design principles but use cloud-native services specific to each provider.

---

## 🏗️ Architecture Comparison

| Component | AWS | Azure |
|-----------|-----|-------|
| **Kubernetes** | EKS (Elastic Kubernetes Service) | AKS (Azure Kubernetes Service) |
| **Load Balancer** | ALB (Application Load Balancer) | Application Gateway (V2) |
| **Node Compute** | EC2 t3.medium | VM Standard_B2s |
| **Storage (Files)** | S3 Bucket | Azure Blob Storage |
| **Storage (Persistent)** | EBS Volumes | Azure Managed Disks |
| **Networking** | VPC with NAT Gateways | VNet with Subnet |
| **Monitoring Logs** | CloudWatch | Log Analytics Workspace |
| **Backup** | S3 versioning | Azure Storage versioning |

---

## 🔷 AWS EKS Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud                                │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                   │   │
│  │                                                         │   │
│  │  ┌─────────────────┐    ┌─────────────────────────────┐ │   │
│  │  │   Public Subnets│    │      Private Subnets        │ │   │
│  │  │   (ALB, NAT)    │    │     (EKS Nodes, Apps)      │ │   │
│  │  │                 │    │                             │ │   │
│  │  │ ┌─────────────┐ │    │ ┌─────────────────────────┐ │ │   │
│  │  │ │     ALB     │ │    │ │      EKS Cluster        │ │ │   │
│  │  │ │             │ │    │ │                         │ │ │   │
│  │  │ │ ┌─────────┐ │ │    │ │ ┌─────────────────────┐ │ │ │   │
│  │  │ │ │Target   │ │ │    │ │ │   RocketChat Pods   │ │ │ │   │
│  │  │ │ │Groups   │ │ │    │ │ │   (2 replicas)      │ │ │ │   │
│  │  │ │ └─────────┘ │ │    │ │ └─────────────────────┘ │ │ │   │
│  │  │ └─────────────┘ │    │ │ ┌─────────────────────┐ │ │ │   │
│  │  │                 │    │ │ │   MongoDB Pods      │ │ │ │   │
│  │  │ ┌─────────────┐ │    │ │ │   (3 replicas)      │ │ │ │   │
│  │  │ │   NAT GW    │ │    │ │ └─────────────────────┘ │ │ │   │
│  │  │ │   (3x)      │ │    │ │ ┌─────────────────────┐ │ │ │   │
│  │  │ └─────────────┘ │    │ │ │  Monitoring Stack  │ │ │ │   │
│  │  └─────────────────┘    │ │ │  (Prometheus/Grafana)│ │ │ │   │
│  │                         │ │ └─────────────────────┘ │ │ │   │
│  │                         │ └─────────────────────────┘ │ │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    External Services                     │   │
│  │                                                         │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   S3 Bucket  │    │   EBS Vols  │    │   CloudWatch │ │   │
│  │  │ (File Store) │    │ (Persistent)│    │   (Logs)     │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Component Details

#### 1. Network Layer (AWS)
- **VPC**: 10.0.0.0/16 across 3 availability zones
- **Public Subnets**: 3 subnets for ALB and NAT Gateways
- **Private Subnets**: 3 subnets for EKS nodes and applications
- **NAT Gateways**: 3 gateways (one per AZ) for outbound internet access
- **Internet Gateway**: Routes traffic between internet and VPC

#### 2. EKS Cluster (AWS)
- **Version**: 1.28+ (latest stable)
- **Endpoint**: Public and private access enabled
- **Logging**: CloudWatch logs enabled
- **Add-ons**: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver

#### 3. Node Group (AWS)
- **Instance Type**: t3.medium (burstable)
- **Scaling**: 2-4 nodes with auto-scaling
- **Storage**: EBS volumes for container images
- **Networking**: Private subnets only

#### 4. Load Balancing (AWS)
- **Type**: Application Load Balancer (ALB)
- **Scheme**: Internet-facing
- **Target Type**: IP (direct pod targeting)
- **Health Checks**: HTTP on `/api/v1/info`
- **SSL/TLS**: Can be configured

#### 5. Storage (AWS)
- **EBS Volumes**: GP3 for general purpose
- **S3 Bucket**: For RocketChat file uploads with versioning
- **Storage Classes**: `ebs-gp3` and `mongodb-storage`

#### 6. Monitoring (AWS)
- **CloudWatch**: Log aggregation and dashboards
- **Prometheus**: Time-series metrics collection
- **Loki**: Log aggregation from Kubernetes pods
- **Tempo**: Distributed tracing for request flows
- **Grafana**: Visualization with pre-built dashboards (all datasources integrated)
- **Promtail**: Log collection agent on all nodes

---

## 🔶 Azure AKS Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Cloud                                │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    VNet (10.0.0.0/16)                   │   │
│  │                                                         │   │
│  │  ┌──────────────────┐   ┌──────────────────────────────┐ │   │
│  │  │ App Gateway      │   │      AKS Subnets            │ │   │
│  │  │ Subnet           │   │     (Nodes, Apps)           │ │   │
│  │  │                  │   │                              │ │   │
│  │  │ ┌──────────────┐ │   │ ┌──────────────────────────┐ │ │   │
│  │  │ │ App Gateway  │ │   │ │    AKS Cluster           │ │ │   │
│  │  │ │              │ │   │ │                          │ │ │   │
│  │  │ │ ┌──────────┐ │ │   │ │ ┌──────────────────────┐ │ │ │   │
│  │  │ │ │Backend   │ │ │   │ │ │  RocketChat Pods    │ │ │ │   │
│  │  │ │ │Pools     │ │ │   │ │ │  (2 replicas)       │ │ │ │   │
│  │  │ │ └──────────┘ │ │   │ │ └──────────────────────┘ │ │ │   │
│  │  │ └──────────────┘ │   │ │ ┌──────────────────────┐ │ │ │   │
│  │  │                  │   │ │ │  MongoDB Pods        │ │ │ │   │
│  │  │ ┌──────────────┐ │   │ │ │  (3 replicas)       │ │ │ │   │
│  │  │ │ Public IP    │ │   │ │ └──────────────────────┘ │ │ │   │
│  │  │ │ (Static)     │ │   │ │ ┌──────────────────────┐ │ │ │   │
│  │  │ └──────────────┘ │   │ │ │ Monitoring Stack     │ │ │ │   │
│  │  │                  │   │ │ │ (P+G+Loki+Tempo)    │ │ │ │   │
│  │  └──────────────────┘   │ │ └──────────────────────┘ │ │ │   │
│  │                         │ └──────────────────────────┘ │ │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Storage Services                      │   │
│  │                                                         │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │   │
│  │  │ Blob Storage │  │ Managed Disks│  │ Log Analytics│ │   │
│  │  │ (File Store) │  │(Persistent)  │  │   (Logs)     │ │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Component Details

#### 1. Network Layer (Azure)
- **VNet**: 10.0.0.0/16 in single region
- **AKS Nodes Subnet**: 10.0.1.0/24 for cluster nodes
- **App Gateway Subnet**: 10.0.2.0/24 for application gateway
- **Network Security Groups**: Control inbound/outbound traffic
- **Service CIDR**: 10.1.0.0/16 for Kubernetes services

#### 2. AKS Cluster (Azure)
- **Version**: 1.31.11+ (latest stable)
- **Endpoint**: Public and private access
- **Logging**: Log Analytics Workspace
- **Network Plugin**: Azure CNI for native VNet integration

#### 3. Node Pool (Azure)
- **Instance Type**: Standard_B2s (burstable)
- **Scaling**: 2-4 nodes with auto-scaling
- **Storage**: Managed disks for container images
- **Networking**: Private subnet within VNet
- **VM Scale Sets**: Underlying infrastructure

#### 4. Load Balancing (Azure)
- **Type**: Application Gateway V2 (Standard_v2 SKU)
- **Public IP**: Static IP for stable endpoint
- **Backend Pools**: For routing to backend services
- **HTTP Settings**: Configurable per backend
- **Health Probes**: Custom probes for health checks
- **SSL Policy**: Modern TLS policy (AppGwSslPolicy20220101)

#### 5. Storage (Azure)
- **Managed Disks**: Premium or Standard LRS for persistent volumes
- **Blob Storage**: For RocketChat file uploads with versioning
- **Storage Accounts**: Separate accounts for files and backups

#### 6. Monitoring (Azure)
- **Log Analytics**: Centralized log aggregation
- **Prometheus**: Time-series metrics collection
- **Loki**: Log aggregation from Kubernetes pods
- **Tempo**: Distributed tracing for request flows
- **Grafana**: Visualization with pre-built dashboards (all datasources integrated)
- **Promtail**: Log collection agent on all nodes

---

## 📊 Shared Components (AWS & Azure)

### Application Layer
- **RocketChat**: 2 replicas with horizontal auto-scaling
- **MongoDB**: 3-replica set for high availability
- **Prometheus**: Metrics collection and alerting (port 9090)
- **Grafana**: Visualization and dashboards (port 3000)
- **Loki**: Log aggregation (port 3100)
- **Tempo**: Distributed tracing (port 3200)

### Observability Stack Integration
```
RocketChat Application (Sends data to monitoring stack)
    ├─ Metrics → Prometheus (9090)
    │   └─ Scraped every 30 seconds
    │
    ├─ Logs → Loki (3100) via Promtail DaemonSet
    │   └─ Collected from all pods
    │
    ├─ Traces → Tempo (3200) via OTLP
    │   └─ Request flow tracing
    │
    └─ All visualized in Grafana (3000)
        ├─ Prometheus datasource (metrics)
        ├─ Loki datasource (logs)
        ├─ Tempo datasource (traces)
        └─ Pre-built dashboards for each component
```

### Configuration Management
- **Helm Charts**: Package and deploy applications
- **ConfigMaps**: Application configuration
- **Secrets**: Sensitive data management (credentials, API keys)
- **RBAC**: Role-based access control

### Networking
- **Services**: Internal service discovery (ClusterIP)
- **Ingress**: External traffic routing (AWS ALB, Azure App Gateway)
- **Network Policies**: Pod-to-pod communication rules
- **DNS**: Kubernetes DNS (CoreDNS)

---

## 🔄 Data Flow

### 1. User Request Flow
```
Internet 
  ↓
[AWS: ALB / Azure: App Gateway]
  ↓
[Kubernetes Service]
  ↓
[RocketChat Pod]
  ↓
[MongoDB Service]
  ↓
[MongoDB Replicas]
```

### 2. File Upload Flow
```
RocketChat Pod
  ↓
[AWS: S3 API / Azure: Blob Storage API]
  ↓
[Persistent Storage]
```

### 3. Monitoring Flow (Metrics)
```
Application Metrics
  ↓
[Prometheus Scraper] (30s intervals)
  ↓
[Time-Series Database] (Prometheus)
  ↓
[Grafana Dashboards]
```

### 4. Logging Flow (NEW - Loki)
```
Pod Logs (stdout/stderr)
  ↓
[Promtail DaemonSet] (Collects from all nodes)
  ↓
[Loki] (Log storage and indexing)
  ↓
[Grafana Logs Datasource] (Query interface)
```

### 5. Tracing Flow (NEW - Tempo)
```
RocketChat Application (OTLP Protocol)
  ↓
[Tempo OTLP Receiver] (Port 4317/4318)
  ↓
[Tempo] (Trace storage)
  ↓
[Grafana Traces Datasource] (Visualization)
  └─ Service graph showing service dependencies
  └─ Latency analysis across services
```

---

## 🎯 High Availability Design

### Multi-AZ/Region (AWS)
- **Availability Zones**: 3 AZs for redundancy
- **Subnets**: Distributed across AZs
- **NAT Gateways**: One per AZ for independent egress
- **ALB**: Automatically multi-AZ

### Multi-Region Capable (Azure)
- **Single Region**: Current deployment in East US
- **Scalable**: Can be replicated to other regions
- **Load Balancing**: Traffic manager for multi-region

### Pod-Level HA
- **RocketChat Replicas**: 2+ pods with pod disruption budgets
- **MongoDB Replica Set**: 3 members with automatic failover
- **Monitoring Stack**: All components have replicas and persistent storage
- **Resource Quotas**: CPU and memory limits prevent resource starvation

### Storage HA
- **EBS Volumes (AWS)**: Automatic snapshots, multi-AZ capable
- **Managed Disks (Azure)**: Built-in redundancy (LRS)
- **Blob Storage (Azure)**: Versioning and soft delete
- **S3 (AWS)**: Versioning and cross-region replication (optional)
- **Loki/Tempo Storage**: Persistent volumes with automatic backups

---

## 📈 Performance Characteristics

### Expected Performance
- **RocketChat**: Supports 100+ concurrent users
- **Response Time**: <2 seconds average
- **Availability**: 99.9% uptime with proper configuration
- **Metrics**: ~1000+ data points per second (Prometheus)
- **Logs**: Retention up to 30 days (Loki)
- **Traces**: Retention up to 7 days (Tempo)

### Scaling Limits
- **Nodes**: Up to 4 instances (t3.medium AWS / Standard_B2s Azure)
- **Pods**: Up to 5 RocketChat replicas
- **Storage**: Dynamic provisioning, scalable on demand
- **Monitoring Metrics**: Auto-scales with application load

### Cost Optimization
- **Burstable Instances**: t3.medium (AWS) / Standard_B2s (Azure)
- **Spot Instances**: Supported for cost savings
- **Auto-scaling**: Right-size to actual demand
- **Log Retention**: Configurable to balance cost vs retention

---

## 🔐 Security Boundaries

### Network Segmentation
- **Public**: Load balancer only
- **Private**: EKS/AKS nodes and applications
- **Internal**: MongoDB and inter-pod communication
- **Monitoring**: Isolated namespace with restricted access

### Access Control
- **IAM/RBAC**: Kubernetes role-based access control
- **Network Policies**: Restrict pod-to-pod communication
- **Security Groups/NSGs**: Control subnet traffic
- **Grafana RBAC**: User roles and dashboard permissions

### Data Protection
- **Encryption at Rest**: EBS, Managed Disks, Storage
- **Encryption in Transit**: TLS for all communications
- **Secrets Management**: Kubernetes secrets with encryption
- **Monitoring Data**: Encrypted storage for logs and traces

---

## 🔄 Disaster Recovery

### Backup Strategy
- **EBS/Managed Disks**: Automated snapshots
- **S3/Blob Storage**: Versioning enabled
- **MongoDB**: Regular backups to cloud storage
- **Prometheus Data**: Persistent volume with automatic retention
- **Loki Data**: Multi-day retention (default 30 days)
- **Tempo Data**: Multi-day retention (default 7 days)

### Recovery Procedures
- **Infrastructure**: Terraform state for quick recovery
- **Applications**: Helm charts for redeployment
- **Data**: Restore from snapshots and backups
- **Monitoring Data**: Restore from backup volumes

### RTO/RPO
- **Recovery Time Objective**: 2-4 hours
- **Recovery Point Objective**: 1 hour
- **Data Loss Risk**: Minimal with proper backups
- **Monitoring Data Loss**: Minimal (persistent storage + backups)

---

## 🔀 Comparison Summary

| Aspect | AWS | Azure |
|--------|-----|-------|
| **Kubernetes Service** | EKS (managed) | AKS (managed) |
| **Load Balancer** | ALB (sophisticated routing) | App Gateway (simpler) |
| **Storage** | S3 (object) + EBS (block) | Blob (object) + Managed Disks (block) |
| **Multi-AZ** | Native (3 AZs standard) | Regional (requires setup) |
| **Cost** | ~$150-200/month | ~$120-180/month |
| **Monitoring** | CloudWatch + Prometheus + Loki + Tempo | Log Analytics + Prometheus + Loki + Tempo |
| **Scaling** | Node and pod auto-scaling | Node and pod auto-scaling |
| **Networking** | VPC (complex) | VNet (simpler) |

---

## 📚 Next Steps

- **For Deployment**: See [deployment.md](deployment.md) and [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)
- **For Monitoring Setup**: See [monitoring-stack.md](monitoring-stack.md)
- **For Operations**: See [operations.md](operations.md)
- **For Troubleshooting**: See [troubleshooting.md](troubleshooting.md)
- **For Implementation Plan**: See [MASTER-PLAN.md](MASTER-PLAN.md)

---

**Last Updated**: October 23, 2025  
**Covers**: AWS EKS + Azure AKS with Full Observability Stack  
**Monitoring**: Prometheus + Grafana + Loki + Tempo (integrated)  
**Applies to**: All phases of implementation
