# Operations Guide (AWS EKS & Azure AKS)

## Day-2 Operations for RocketChat Kubernetes Deployments

---

## Scaling Operations

### 1. Scaling Kubernetes Node Group

#### AWS EKS

**Manual Scaling:**
```bash
# Scale node group
aws eks update-nodegroup-config \
  --cluster-name rocketchat-eks-production \
  --nodegroup-name rocketchat-eks-production-nodes \
  --scaling-config minSize=3,maxSize=6,desiredSize=4

# Verify scaling
kubectl get nodes
```

#### Azure AKS

**Manual Scaling:**
```bash
# Scale node pool
az aks scale \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks \
  --node-count 3

# Verify scaling
kubectl get nodes
```

### 2. Autoscaling Configuration (Both)

```bash
# Check current auto-scaling
kubectl get hpa -n rocketchat

# Update auto-scaling settings
kubectl patch hpa rocketchat -n rocketchat -p '{"spec":{"minReplicas":3,"maxReplicas":8}}'
```

### 3. Scaling RocketChat Application (Both)

**Horizontal Pod Autoscaler:**
```bash
# Check current HPA
kubectl get hpa -n rocketchat

# Scale manually
kubectl scale deployment rocketchat -n rocketchat --replicas=5

# Update HPA
kubectl patch hpa rocketchat -n rocketchat -p '{"spec":{"minReplicas":3,"maxReplicas":10}}'
```

**Vertical Scaling:**
```bash
# Update resource limits
kubectl patch deployment rocketchat -n rocketchat -p '{"spec":{"template":{"spec":{"containers":[{"name":"rocketchat","resources":{"limits":{"cpu":"2000m","memory":"2Gi"}}}]}}}}'
```

---

## Upgrading Operations

### 1. Kubernetes Cluster Upgrade

#### AWS EKS

**Check Current Version:**
```bash
aws eks describe-cluster --name rocketchat-eks-production --query 'cluster.version'
```

**Upgrade Cluster:**
```bash
# Update terraform.tfvars
# Change: eks_cluster_version = "1.28" to "1.29"

# Apply changes
cd AWS/terraform
terraform plan
terraform apply
```

#### Azure AKS

**Check Current Version:**
```bash
az aks show \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks \
  --query kubernetesVersion
```

**Upgrade Cluster:**
```bash
# Update terraform.tfvars
# Change: aks_cluster_version = "1.31.11" to "1.32.0"

# Apply changes
cd AZURE/terraform
terraform plan
terraform apply
```

### 2. Node Group AMI Update (AWS Only)

```bash
# Update node group AMI
aws eks update-nodegroup-config \
  --cluster-name rocketchat-eks-production \
  --nodegroup-name rocketchat-eks-production-nodes \
  --ami-type AL2_x86_64
```

### 3. RocketChat Upgrade (Both)

**Check Current Version:**
```bash
kubectl get deployment rocketchat -n rocketchat -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Upgrade via Helm:**
```bash
# Check available versions
helm search repo rocketchat/rocketchat --versions

# Upgrade
helm upgrade rocketchat rocketchat/rocketchat -n rocketchat \
  --set image.tag=6.2.0

# Verify upgrade
kubectl rollout status deployment rocketchat -n rocketchat
```

### 4. Monitoring Stack Upgrade (Both)

**Upgrade Prometheus:**
```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring \
  --values helm/prometheus-values.yaml
```

**Upgrade Grafana:**
```bash
helm upgrade grafana grafana/grafana -n monitoring \
  --values helm/grafana-values.yaml
```

---

## Backup and Restore

### 1. MongoDB Backup (Both)

**Create Backup:**
```bash
# Create backup job
kubectl create job mongodb-backup-$(date +%Y%m%d) -n rocketchat \
  --image=mongo:4.4 \
  -- mongodump --host=mongodb:27017 --out=/backup
```

**Copy to Cloud Storage:**

#### AWS (S3)
```bash
# From pod to S3
kubectl exec -n rocketchat deployment/mongodb -- \
  aws s3 cp /backup s3://rocketchat-files/backups/$(date +%Y%m%d)/ --recursive
```

#### Azure (Blob Storage)
```bash
# From pod to Blob Storage
kubectl exec -n rocketchat deployment/mongodb -- \
  az storage blob upload-batch \
  --source /backup \
  --destination rocketchat-files \
  --account-name <storage-account-name>
```

**Restore from Backup:**
```bash
# Download backup from cloud storage
# (AWS S3 or Azure Blob Storage specific command)

# Restore database
kubectl exec -n rocketchat deployment/mongodb -- \
  mongorestore --host=mongodb:27017 /restore/
```

### 2. Persistent Volume Backup

#### AWS (EBS Snapshots)

```bash
# List EBS volumes
aws ec2 describe-volumes --filters "Name=tag:Name,Values=*rocketchat*"

# Create snapshots
aws ec2 create-snapshot \
  --volume-id vol-1234567890abcdef0 \
  --description "RocketChat backup $(date +%Y%m%d)"

# Restore from snapshot
aws ec2 create-volume \
  --snapshot-id snap-1234567890abcdef0 \
  --availability-zone us-east-1a \
  --volume-type gp3
```

#### Azure (Managed Disk Snapshots)

```bash
# Create snapshot
az snapshot create \
  --resource-group rocketchat-aks-rg \
  --name rocket-disk-snapshot-$(date +%Y%m%d) \
  --source <disk-id>

# Create disk from snapshot
az disk create \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-disk-restored \
  --source <snapshot-id>
```

### 3. Application Data Backup

#### AWS (S3)

```bash
# Enable versioning (if not already enabled)
aws s3api put-bucket-versioning \
  --bucket rocketchat-files \
  --versioning-configuration Status=Enabled

# Cross-region replication
aws s3api put-bucket-replication \
  --bucket rocketchat-files \
  --replication-configuration file://replication.json

# Backup to different bucket
aws s3 sync s3://rocketchat-files s3://rocketchat-files-backup
```

#### Azure (Blob Storage)

```bash
# Enable versioning (already enabled in Terraform)
az storage account blob-service-properties update \
  --account-name <storage-account-name> \
  --enable-versioning

# Backup to different storage account
az storage blob copy start-batch \
  --source-account-name <source-account> \
  --source-container rocketchat-files \
  --destination-account-name <dest-account> \
  --destination-container rocketchat-files-backup
```

---

## Monitoring and Alerting

### 1. Prometheus Alerts (Both)

**Create Alert Rules:**
```yaml
# prometheus-alerts.yaml
groups:
- name: rocketchat
  rules:
  - alert: RocketChatDown
    expr: up{job="rocketchat"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "RocketChat is down"
      description: "RocketChat has been down for more than 5 minutes"
```

**Apply Alerts:**
```bash
kubectl apply -f prometheus-alerts.yaml
```

### 2. Grafana Dashboards (Both)

**Import Dashboards:**
```bash
# Get Grafana pod name
GRAFANA_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')

# Port forward
kubectl port-forward -n monitoring $GRAFANA_POD 3000:3000

# Access: http://localhost:3000
# Import dashboard JSON via UI
```

### 3. Logging and Monitoring

#### AWS (CloudWatch)

```bash
# Check logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/rocketchat

# Get recent logs
aws logs tail /aws/eks/rocketchat-eks-production --follow
```

#### Azure (Log Analytics)

```bash
# Query logs
az monitor log-analytics query \
  --workspace rocketchat-aks-logs \
  --analytics-query "ContainerLog | where ContainerID == '<container-id>' | tail 100"
```

---

## Cost Optimization

### 1. Right-Sizing (Both)

**Analyze Resource Usage:**
```bash
# Check resource utilization
kubectl top nodes
kubectl top pods --all-namespaces

# Check storage usage
kubectl get pv
kubectl get pvc --all-namespaces
```

**Optimize Resources:**
```bash
# Update resource requests/limits
kubectl patch deployment rocketchat -n rocketchat -p '{"spec":{"template":{"spec":{"containers":[{"name":"rocketchat","resources":{"requests":{"cpu":"250m","memory":"256Mi"}}}]}}}}'
```

### 2. Storage Optimization (Both)

**Clean Up Old Data:**
```bash
# Clean up old Prometheus data
kubectl exec -n monitoring deployment/prometheus-server -- \
  find /prometheus -name "*.db" -mtime +30 -delete

# Clean up old logs
kubectl exec -n rocketchat deployment/rocketchat -- \
  find /app/logs -name "*.log" -mtime +7 -delete
```

### 3. Spot/Low-Priority Instances

#### AWS (Spot Instances)

```bash
# Update node group to use spot instances
aws eks update-nodegroup-config \
  --cluster-name rocketchat-eks-production \
  --nodegroup-name rocketchat-eks-production-nodes \
  --instance-types t3.medium,t3a.medium
```

#### Azure (Low-Priority VMs)

```bash
# Update node pool for spot VMs
az aks nodepool update \
  --resource-group rocketchat-aks-rg \
  --cluster-name rocketchat-aks \
  --name default \
  --enable-spot \
  --spot-max-price 0.10  # Set max price
```

### 4. Network Optimization

#### AWS (NAT Gateway)

```bash
# Check NAT Gateway usage
aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=*rocketchat*"

# Consider NAT Instances for cost savings (less HA)
```

#### Azure (Virtual Network)

```bash
# Check outbound data transfer
az monitor metrics list \
  --resource /subscriptions/<sub-id>/resourceGroups/rocketchat-aks-rg/providers/Microsoft.Network/publicIPAddresses/app-gateway-pip \
  --metric BytesOutDDoS
```

---

## Maintenance Windows

### 1. Scheduled Maintenance (Both)

**Plan Maintenance:**
```bash
# Create maintenance cronjob
kubectl create cronjob maintenance-window \
  --image=busybox \
  --schedule="0 2 * * SUN" \
  -n kube-system \
  -- /bin/sh -c "echo 'Maintenance window: $(date)'"
```

### 2. Rolling Updates (Both)

**Update Deployment:**
```bash
# Set new image
kubectl set image deployment/rocketchat rocketchat=rocketchat/rocket.chat:6.2.0 -n rocketchat

# Monitor rollout
kubectl rollout status deployment/rocketchat -n rocketchat

# Rollback if needed
kubectl rollout undo deployment/rocketchat -n rocketchat
```

### 3. Security Updates (Both)

**Update Base Images:**
```bash
# Update RocketChat
kubectl set image deployment/rocketchat rocketchat=rocketchat/rocket.chat:6.2.0 -n rocketchat

# Update MongoDB
kubectl set image deployment/mongodb mongodb=mongo:4.4.18 -n rocketchat
```

**Security Scanning:**
```bash
# Scan images for vulnerabilities (requires trivy)
trivy image rocketchat/rocket.chat:6.2.0
trivy image mongo:4.4.18
```

---

## Troubleshooting Operations

### 1. Performance Issues (Both)

**Check Resource Usage:**
```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check disk usage
kubectl exec -n rocketchat deployment/rocketchat -- df -h
```

**Optimize Performance:**
```bash
# Scale up if needed
kubectl scale deployment rocketchat -n rocketchat --replicas=5

# Check for resource limits
kubectl describe pod -n rocketchat -l app=rocketchat
```

### 2. Storage Issues (Both)

**Check Storage:**
```bash
# Check PVC status
kubectl get pvc --all-namespaces

# Check storage classes
kubectl get storageclass
```

**Resize Storage:**
```bash
# Resize PVC
kubectl patch pvc mongodb-pvc -n rocketchat -p '{"spec":{"resources":{"requests":{"storage":"50Gi"}}}}'
```

### 3. Network Issues (Both)

**Check Connectivity:**
```bash
# Test internal connectivity
kubectl run debug --image=busybox --rm -it -- nslookup mongodb.rocketchat.svc.cluster.local

# Test external connectivity
kubectl run debug --image=busybox --rm -it -- nslookup google.com
```

---

## Disaster Recovery

### 1. Complete Infrastructure Recovery

#### AWS

```bash
# Backup state file
aws s3 cp terraform.tfstate s3://terraform-state-backup/rocketchat-eks.tfstate

# Restore and reapply
aws s3 cp s3://terraform-state-backup/rocketchat-eks.tfstate terraform.tfstate
terraform plan
terraform apply
```

#### Azure

```bash
# Backup state file
az storage blob upload \
  --account-name <tfstate-account> \
  --container-name tfstate \
  --name rocketchat-backup-$(date +%Y%m%d).tfstate \
  --file terraform.tfstate

# Restore and reapply
terraform plan
terraform apply
```

### 2. Application Recovery (Both)

**Restore from Backup:**
```bash
# Restore MongoDB
kubectl exec -n rocketchat deployment/mongodb -- \
  mongorestore --host=mongodb:27017 /backup/

# Restore file data (S3/Blob Storage specific)
# (See Backup section for cloud-specific commands)
```

---

## Best Practices

### 1. Operational Excellence

- **Monitoring**: Set up comprehensive monitoring and alerting
- **Backups**: Regular automated backups (daily minimum)
- **Documentation**: Keep runbooks updated
- **Testing**: Regular disaster recovery drills

### 2. Security

- **Updates**: Regular security and patch updates
- **Access**: Principle of least privilege
- **Encryption**: Encrypt data at rest and in transit
- **Auditing**: Regular security audits

### 3. Cost Management

- **Monitoring**: Track costs and usage
- **Optimization**: Regular right-sizing
- **Automation**: Use spot instances where possible
- **Cleanup**: Regular cleanup of unused resources

### 4. Reliability

- **Auto-scaling**: Enable and configure properly
- **Health checks**: Ensure all health probes are working
- **Multi-zone**: Distribute across availability zones (AWS) or regions
- **Redundancy**: Multiple replicas for critical services

---

**Last Updated**: October 23, 2025  
**Covers**: AWS EKS + Azure AKS  
**Status**: Comprehensive dual-cloud operations guide
