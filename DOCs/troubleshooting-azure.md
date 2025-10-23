# Azure AKS Troubleshooting Guide

**For AWS EKS, see [troubleshooting-aws.md](troubleshooting-aws.md)**

---

## 1. AKS Cluster Access Problems

### Issue: `kubectl` cannot connect to cluster
```bash
Error: unable to connect to server: dial tcp: lookup <cluster-endpoint>: no such host
```

**Solution:**
```bash
# Get credentials and update kubeconfig
az aks get-credentials \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks \
  --admin

# Verify cluster endpoint
az aks show \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks \
  --query fqdn
```

### Issue: Authentication errors
```bash
Error: You must be logged in to the server (Unauthorized)
```

**Solution:**
```bash
# Check Azure login
az account show

# Re-authenticate
az login

# For service principal
az login --service-principal \
  --username <client-id> \
  --password <client-secret> \
  --tenant <tenant-id>
```

### Issue: Tenant authentication errors in sandbox
```bash
Error: AADSTS90002: Tenant 'tenant-id' not found
```

**Solution:**
```bash
# Use the correct tenant ID from Cloud Shell
az account show
# Note the homeTenantId (not tenantId in the output)

# Use service principal with correct tenant ID
az login --service-principal \
  --username <client-id> \
  --password <client-secret> \
  --tenant <homeTenantId>
```

---

## 2. Pod Scheduling Failures

### Issue: Pods stuck in Pending state
```bash
kubectl get pods -n rocketchat
# Shows: Pending
```

**Diagnosis:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n rocketchat

# Check node resources
kubectl top nodes
```

**Solutions:**
```bash
# Scale node pool
az aks scale \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks \
  --node-count 3

# Check storage classes
kubectl get storageclass
```

### Issue: Node count exceeds sandbox limits
```bash
Error: The subscription does not have enough quota
```

**Diagnosis:**
```bash
# Check current node configuration
grep -n "node_count\|min_count\|max_count" aks.tf
cat terraform.tfvars | grep "count"

# Check current AKS clusters
az aks list --output table
```

**Solutions:**
```bash
# Adjust max_count to respect sandbox limits (max 3 nodes)
sed -i 's/max_count = 4/max_count = 3/' terraform.tfvars

# Verify the change
grep "max_count" terraform.tfvars
```

---

## 3. Storage Provisioning Issues

### Issue: PVC stuck in Pending state
```bash
kubectl get pvc -n rocketchat
# Shows: Pending
```

**Diagnosis:**
```bash
# Check PVC events
kubectl describe pvc <pvc-name> -n rocketchat

# Check disk CSI driver
kubectl get pods -n kube-system | grep disk-csi

# Check managed disk quota
az vm list-usage --location eastus
```

**Solutions:**
```bash
# Restart CSI driver
kubectl delete pod -n kube-system -l app=disk-csi-controller

# Check Azure quotas
az vm list-usage --location eastus --output table
```

---

## 4. Load Balancer Configuration Problems

### Issue: Application Gateway backend pools empty
```bash
az network application-gateway backend-pool list \
  --resource-group rocketchat-aks-rg \
  --gateway-name rocketchat-aks-app-gateway
```

**Diagnosis:**
```bash
# Check Application Gateway health probes
az network application-gateway probe list \
  --resource-group rocketchat-aks-rg \
  --gateway-name rocketchat-aks-app-gateway

# Check backend pool targets
az network application-gateway address-pool list \
  --resource-group rocketchat-aks-rg \
  --gateway-name rocketchat-aks-app-gateway
```

**Solutions:**
```bash
# Update health probe host
az network application-gateway probe update \
  --resource-group rocketchat-aks-rg \
  --gateway-name rocketchat-aks-app-gateway \
  --name rocketchatProbe \
  --pick-host-name-from-backend-settings true

# Restart Application Gateway
az network application-gateway restart \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks-app-gateway
```

### Issue: Application Gateway routing rules conflict
```bash
Error: Two Request Routing Rules are using the same Http Listener
```

**Solution:**
```bash
# Use a single routing rule with path-based routing
request_routing_rule {
  name                       = "mainRoutingRule"
  rule_type                  = "PathBasedRouting"
  http_listener_name         = "httpListener"
  url_path_map_name         = "mainPathMap"
  priority                   = 100
}
```

### Issue: Application Gateway deprecated TLS policy
```bash
Error: The TLS policy AppGwSslPolicy20150501 is using a deprecated TLS version
```

**Solution:**
```bash
# Add modern SSL policy to Application Gateway
ssl_policy {
  policy_type = "Predefined"
  policy_name = "AppGwSslPolicy20220101"
}
```

### Issue: Application Gateway V2 NSG blocking traffic
```bash
Error: ApplicationGatewaySubnetInboundTrafficBlockedByNetworkSecurityGroup
```

**Solution:**
```bash
# Application Gateway V2 SKU doesn't allow NSG on its subnet
# Remove the NSG association for Application Gateway subnet
# Keep the NSG resource but don't associate it with the subnet
```

---

## 5. DNS and Networking Issues

### Issue: Cannot access RocketChat via Application Gateway
```bash
curl http://<app-gateway-ip>
# Returns: Connection refused or timeout
```

**Diagnosis:**
```bash
# Check Application Gateway status
az network application-gateway show \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks-app-gateway

# Check Network Security Groups
az network nsg rule list \
  --resource-group rocketchat-aks-rg \
  --nsg-name rocketchat-aks-nodes-nsg
```

**Solutions:**
```bash
# Add NSG rule for HTTP
az network nsg rule create \
  --resource-group rocketchat-aks-rg \
  --nsg-name rocketchat-aks-nodes-nsg \
  --name AllowHTTP \
  --priority 1000 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-port-ranges '*' \
  --destination-port-ranges 80 \
  --source-address-prefixes '*'
```

---

## 6. MongoDB Connection Issues

### Issue: RocketChat cannot connect to MongoDB
```bash
kubectl logs -n rocketchat -l app.kubernetes.io/name=rocketchat
# Shows: MongoDB connection errors
```

**Diagnosis:**
```bash
# Check MongoDB pods
kubectl get pods -n rocketchat -l app.kubernetes.io/name=mongodb

# Check MongoDB logs
kubectl logs -n rocketchat -l app.kubernetes.io/name=mongodb

# Check MongoDB service
kubectl get svc -n rocketchat mongodb
```

**Solutions:**
```bash
# Restart MongoDB
kubectl delete pod -n rocketchat -l app.kubernetes.io/name=mongodb

# Check MongoDB replica set status
kubectl exec -n rocketchat mongodb-0 -- mongo --eval "rs.status()"
```

---

## 7. Blob Storage Access Issues

### Issue: File uploads failing
```bash
kubectl logs -n rocketchat -l app.kubernetes.io/name=rocketchat
# Shows: Blob storage access denied errors
```

**Diagnosis:**
```bash
# Check storage account access
az storage account show \
  --name <storage-account-name> \
  --resource-group rocketchat-aks-rg

# Test storage access
az storage blob list \
  --container-name rocketchat-files \
  --account-name <storage-account-name>
```

**Solutions:**
```bash
# Get storage account key
STORAGE_KEY=$(az storage account keys list \
  --resource-group rocketchat-aks-rg \
  --account-name <storage-account-name> \
  --query '[0].value' -o tsv)

# Update Kubernetes secret
kubectl create secret generic azure-storage-secret \
  --from-literal=access-key=$STORAGE_KEY \
  -n rocketchat --dry-run=client -o yaml | kubectl apply -f -

# Restart RocketChat pods
kubectl delete pod -n rocketchat -l app.kubernetes.io/name=rocketchat
```

---

## Terraform Azure Provider Issues

### Issue: Terraform plan fails with incorrect arguments
```bash
Error: Too many command line arguments
```

**Solution:**
```bash
# Use correct terraform plan syntax
terraform plan  # NOT terraform plan filename
```

### Issue: Resource provider registration permissions error
```bash
Error: Terraform does not have the necessary permissions to register Resource Providers
```

**Solution:**
```bash
# Add to provider "azurerm" block in main.tf
provider "azurerm" {
  features {}
  
  # Disable automatic resource provider registration for sandbox environments
  skip_provider_registration = true
}
```

### Issue: Azure storage account naming validation error
```bash
Error: name can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
```

**Solution:**
```bash
# Use random string for unique storage account names
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_storage_account" "example" {
  name = "rc${random_string.storage_suffix.result}files"
  # ... other configuration
}
```

### Issue: Kubernetes version not supported error
```bash
Error: K8sVersionNotSupported - version is not supported in this region
Error: version is only available for Long-Term Support (LTS) - requires Premium tier
```

**Solution:**
```bash
# Check supported versions first
az aks get-versions --location eastus --output table

# Use a supported Kubernetes version in terraform.tfvars
aks_cluster_version = "1.31.11"  # Use version that works with Free tier
```

### Issue: Helm chart version not found
```bash
Error: chart "rocketchat" version "1.0.0" not found in repository
```

**Solution:**
```bash
# Remove version specification to use latest available version
resource "helm_release" "rocketchat" {
  name       = "rocketchat"
  repository = "https://rocketchat.github.io/helm-charts"
  chart      = "rocketchat"
  # Remove version line to use latest
  namespace  = kubernetes_namespace.rocketchat.metadata[0].name
}
```

### Issue: Terraform state references old resource group
```bash
Error: AuthorizationFailed - The client does not have authorization to perform action
(trying to access resources in old resource group you no longer have access to)
```

**Common Cause**: Switching to a different resource group in sandbox environments. Terraform state still has old resources from previous RG.

**Solution:**
```bash
# Clean state and start fresh with new resource group
cd AZURE/terraform
rm -rf .terraform terraform.tfstate* aks.tfplan

# Update resource group in terraform.tfvars FIRST
nano terraform.tfvars
# Change: resource_group_name = "1-5418175f-playground-sandbox"

# Reinitialize and plan
terraform init
terraform plan -out=aks.tfplan
```

**Why This Works**:
- Removes local state files referencing old resources
- `.terraform` lock file also removed for fresh provider initialization
- New plan targets ONLY the new resource group
- Avoids trying to refresh non-existent resources

### Issue: RocketChat passwords array error
```bash
Error: passwords array must have at least one entry
```

**Solution:**
```bash
# Minimal MongoDB configuration with passwords array
mongodb:
  enabled: true
  replicaCount: 1
  persistence:
    enabled: false
  auth:
    enabled: false
  passwords:
    - "rocketchat123"
```

---

## Kubernetes Debugging Commands

### General Debugging
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### Network Debugging
```bash
# Check services and endpoints
kubectl get svc --all-namespaces
kubectl get endpoints --all-namespaces

# Test connectivity
kubectl run debug --image=busybox --rm -it -- nslookup <service-name>
```

### Storage Debugging
```bash
# Check persistent volumes
kubectl get pv
kubectl get pvc --all-namespaces

# Check storage classes
kubectl get storageclass
```

### Log Collection
```bash
# Create logs directory
mkdir -p logs

# Collect pod logs
kubectl logs --all-containers=true -n rocketchat > logs/rocketchat.log
kubectl logs --all-containers=true -n monitoring > logs/monitoring.log
kubectl logs --all-containers=true -n kube-system > logs/kube-system.log

# Collect events
kubectl get events --all-namespaces > logs/events.log

# Check AKS cluster
az aks show \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks

# Check VMs
az vm list --resource-group rocketchat-aks-rg

# Check Application Gateway
az network application-gateway show \
  --resource-group rocketchat-aks-rg \
  --name rocketchat-aks-app-gateway
```

---

## Emergency Procedures

### Complete Cluster Reset
```bash
# WARNING: This will delete everything!
cd AZURE/terraform
terraform destroy -auto-approve
terraform apply
```

### Quick Recovery
```bash
# Restart all deployments
kubectl rollout restart deployment -n rocketchat
kubectl rollout restart deployment -n monitoring

# Restart all pods
kubectl delete pods --all -n rocketchat
kubectl delete pods --all -n monitoring
```

---

## Getting Help

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/)
- [Azure Support Center](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)
- Check Terraform state: `terraform show`
- Review Azure Activity Log: For API call errors
- Community Forums: AKS, Terraform, and RocketChat communities

---

**Last Updated**: October 23, 2025  
**Platform**: Azure AKS only  
**Related**: [troubleshooting-aws.md](troubleshooting-aws.md) for AWS EKS issues

## 8. Sandbox Access and Networking

### Issue: External IP times out on Service type LoadBalancer
```bash
curl -I http://<EXTERNAL-IP>  # times out
```

**Common sandbox causes:**
- NSG on AKS nodes blocks NodePort range (30000-32767)
- LB health probe protocol/path not set (HTTP path mismatch)
- Restricted subscription prevents viewing/fixing managed `kubernetes` LB in node RG

**Fixes:**
```bash
# Allow NodePort range from Azure LB (NSG on AKS nodes)
az network nsg rule create \
  -g <rg> \
  --nsg-name <nodes-nsg> \
  --name AllowNodePortsFromAzureLB \
  --priority 1000 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes AzureLoadBalancer \
  --destination-port-ranges 30000-32767

# Set HTTP health probe annotations and re-reconcile
kubectl -n rocketchat annotate svc rocketchat-rocketchat \
  service.beta.kubernetes.io/azure-load-balancer-health-probe-protocol=Http --overwrite
kubectl -n rocketchat annotate svc rocketchat-rocketchat \
  service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path=/livez --overwrite
```

If RBAC prevents inspecting the managed LB in the node RG, use port-forward (below) to validate.

### Issue: Cloud Shell Web preview shows "Unauthorized" or rejects URL

**Notes:**
- Cloud Shell Web preview expects a port number only (not a URL)
- Allowed ranges are 1025–8079 and 8091–49151 (8080 is not allowed)

**Use port-forward with allowed ports:**
```bash
# Rocket.Chat service currently exposes 80 -> 3000 internally
kubectl -n rocketchat port-forward svc/rocketchat-rocketchat 3000:80
# Preview: enter 3000 (not a URL)

# If service forward fails, forward the deployment to the container port
kubectl -n rocketchat port-forward deploy/rocketchat-rocketchat 3000:3000

# Grafana
kubectl -n monitoring port-forward svc/grafana 3001:80
# or
kubectl -n monitoring port-forward deploy/grafana 3001:3000
```

## 9. Loki Configuration Issues

### Issue: `chart "loki-stack" version "2.9.3" not found`

**Cause**: The `loki-stack` Helm chart was deprecated and replaced with individual `grafana/loki` chart.

**Fix Applied** (Phase 0):
```hcl
# Change from:
chart = "loki-stack"
version = "2.9.3"

# To:
chart = "loki"
repository = "https://grafana.github.io/helm-charts"
# No version pin; uses latest
```

### Issue: `nil pointer evaluating interface {}.chunks` (Loki template error)

**Cause**: Old `loki-stack` configuration syntax doesn't work with new `grafana/loki` chart. Template tries to access nested config that doesn't exist.

**Error Output**:
```
error calling include: template: loki/templates/config.yaml:19:7: 
executing "loki/templates/config.yaml" at <include "loki.calculatedConfig" .>: 
error calling include: ... 
nil pointer evaluating interface {}.chunks
```

**Root Cause**: Using `set` blocks with old `loki.storage.*` syntax instead of values file with single-binary mode config.

**Fix Applied** (Phase 0):
- Created `AZURE/helm/loki-values.yaml` with single-binary configuration
- Wired into `AZURE/terraform/helm.tf` using `values = [file(...)]`
- Removed conflicting `set` blocks

**New Configuration** (`AZURE/helm/loki-values.yaml`):
```yaml
loki:
  auth_enabled: false

singleBinary:
  enabled: true

lokiStorageType: filesystem

persistence:
  enabled: true
  size: 10Gi
  storageClassName: azure-disk

enterprise:
  enabled: false

resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi
```

**Terraform Integration** (`AZURE/terraform/helm.tf`):
```hcl
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [file("${path.module}/../helm/loki-values.yaml")]

  depends_on = [helm_release.grafana]
}
```

### Issue: Loki pods stuck in pending or CrashLoopBackOff

**Check Loki status:**
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=loki
kubectl logs -n monitoring -l app.kubernetes.io/name=loki --tail=50
kubectl describe pvc -n monitoring | grep -i loki

# Check if storage class exists
kubectl get storageclass
# Expected: azure-disk, azure-file present
```

**Common causes & fixes:**
- **No storage**: Ensure `azure-disk` storage class exists (created by AKS)
- **PVC stuck pending**: Node might be NotReady; wait 5 mins for cluster stabilization
- **Config error**: Verify `loki-values.yaml` syntax and mounted correctly

**Verify Loki is healthy:**
```bash
# Port-forward to test
kubectl -n monitoring port-forward svc/loki 3100:3100

# In another terminal, test readiness
curl -s http://localhost:3100/ready
# Expected: 200 OK

# Query logs (if any collected)
curl -s http://localhost:3100/loki/api/v1/label
```
