# RocketChat Kubernetes Deployment Guide

## Prerequisites

### Required Tools
- **Cloud Provider CLI** (AWS CLI v2.0+ or Azure CLI v2.0+)
- **Terraform** (v1.0+) - [Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **kubectl** (v1.28+) - [Install Guide](https://kubernetes.io/docs/tasks/tools/)
- **Helm** (v3.0+) - [Install Guide](https://helm.sh/docs/intro/install/)

### Cloud Provider Requirements

#### AWS Requirements
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Sufficient AWS service limits for:
  - EKS clusters (1)
  - EC2 instances (2-4 t3.medium)
  - Application Load Balancers (1)
  - NAT Gateways (3)

#### Azure Requirements
- Azure subscription with appropriate permissions
- Azure CLI configured with credentials
- Sufficient Azure service limits for:
  - AKS clusters (max 3 in sandbox)
  - VM instances (max 3 nodes per cluster in sandbox)
  - Application Gateways (1)
  - Load Balancers (1)

## Step-by-Step Deployment

### 1. Clone and Navigate to Project

#### For AWS:
```bash
cd Terraform_RC_deployments/AWS/terraform
```

#### For Azure:
```bash
cd Terraform_RC_deployments/AZURE/terraform
```

### 2. Configure Cloud Provider Credentials

#### For AWS:
```bash
# Option 1: AWS CLI Configure
aws configure

# Option 2: Environment Variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 3: AWS SSO
aws sso login --profile your-profile
```

#### For Azure:
```bash
# Option 1: Interactive Login
az login

# Option 2: Service Principal (for CI/CD or sandbox)
az login --service-principal \
  --username <client-id> \
  --password <client-secret> \
  --tenant <tenant-id>

# Option 3: Azure Cloud Shell (recommended for sandbox)
# Access via Azure portal - already authenticated

# Verify authentication
az account show
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review Configuration

#### Environment-Specific Configuration Files

**NEW in Phase B**: Use environment-specific tfvars files for different environments:

```bash
# Available environment configurations:
# - terraform.sandbox.tfvars  (minimal resources, cost-optimized)
# - terraform.dev.tfvars      (moderate resources, development)
# - terraform.prod.tfvars     (full resources, production-ready)
```

#### For AWS:
```bash
# Review variables for specific environment
cat terraform.sandbox.tfvars   # or terraform.dev.tfvars, terraform.prod.tfvars

# Review planned changes for sandbox
terraform plan -var-file=terraform.sandbox.tfvars -out=sandbox.tfplan

# For development
terraform plan -var-file=terraform.dev.tfvars -out=dev.tfplan

# For production
terraform plan -var-file=terraform.prod.tfvars -out=prod.tfplan
```

#### For Azure:
```bash
# Review variables for specific environment
cat terraform.sandbox.tfvars   # or terraform.dev.tfvars, terraform.prod.tfvars

# For sandbox (respects 3-cluster, 3-node limits)
terraform plan -var-file=terraform.sandbox.tfvars -out=sandbox.tfplan

# For development (requires dedicated resource group)
terraform plan -var-file=terraform.dev.tfvars -out=dev.tfplan

# For production (full resources)
terraform plan -var-file=terraform.prod.tfvars -out=prod.tfplan
```

#### Legacy Configuration (Not Recommended)
```bash
# Using default terraform.tfvars (kept for reference only)
terraform plan
```

### 5. Deploy Infrastructure

#### Using Environment-Specific Configuration (Recommended)
```bash
# Apply saved plan file for sandbox
terraform apply sandbox.tfplan

# Or for development
terraform apply dev.tfplan

# Or for production
terraform apply prod.tfplan

# Deployment takes 15-20 minutes
```

#### Legacy Deployment (Not Recommended)
```bash
# Apply changes using default terraform.tfvars
terraform apply

# Type 'yes' when prompted
```

**Note**: Using environment-specific tfvars ensures deterministic deployments with predictable resource naming based on the `deployment_id`.

### 6. Configure kubectl

#### For AWS:
```bash
# Get the command from terraform output
aws eks update-kubeconfig --region us-east-1 --name rocketchat-eks-production

# Verify cluster access
kubectl get nodes
```

#### For Azure:
```bash
# Get credentials for the AKS cluster
az aks get-credentials --resource-group rocketchat-aks-rg --name rocketchat-aks

# Verify cluster access
kubectl get nodes
```

### 7. Verify Deployment
```bash
# Check all pods are running
kubectl get pods --all-namespaces

# Check RocketChat deployment
kubectl get pods -n rocketchat

# Check monitoring stack
kubectl get pods -n monitoring
```

### 8. Access Applications

#### Get Load Balancer URL
```bash
# From Terraform output
terraform output alb_dns_name

# Or from kubectl
kubectl get ingress -n rocketchat
```

#### Access RocketChat
- URL: `http://<ALB_DNS_NAME>`
- Default admin credentials will be displayed in pod logs

#### Access Grafana
- URL: `http://<ALB_DNS_NAME>/grafana`
- Username: `admin`
- Password: `admin123`

**New Features Available:**
- **Loki Integration**: Log aggregation and querying
- **Tempo Integration**: Distributed tracing
- **Enhanced Dashboards**: 
  - RocketChat Metrics (ID: 23428)
  - RocketChat Microservices (ID: 23427)
  - Node Exporter Full (ID: 1860)
  - Kubernetes Deployment (ID: 741)
  - Kubernetes Pod (ID: 740)
  - Kubernetes Node (ID: 739)
  - Ingress NGINX (ID: 20275)
  - Ingress Traefik (ID: 17347)

## Verification Checklist

- [ ] EKS cluster is running
- [ ] All pods are in Running state
- [ ] RocketChat is accessible via ALB
- [ ] Grafana is accessible via ALB
- [ ] MongoDB is running with 3 replicas
- [ ] S3 bucket is created for file uploads
- [ ] Prometheus is collecting metrics
- [ ] Load balancer health checks are passing

## Expected Resources

After successful deployment, you should have:
- 1 EKS Cluster (rocketchat-eks-production)
- 2-4 EC2 instances (t3.medium)
- 1 VPC with public/private subnets
- 3 NAT Gateways
- 1 Application Load Balancer
- 1 S3 bucket for file uploads
- Multiple EBS volumes for persistent storage

## Estimated Costs

- **Monthly Cost**: ~$150-200 USD
- **Breakdown**:
  - EKS Cluster: ~$73/month
  - EC2 instances (2x t3.medium): ~$60/month
  - NAT Gateways (3x): ~$135/month
  - Application Load Balancer: ~$20/month
  - EBS Storage: ~$10/month
  - S3 Storage: ~$5/month

## Next Steps

1. **Configure DNS**: Point your domain to the ALB DNS name
2. **SSL Certificate**: Add SSL/TLS certificate for HTTPS
3. **Backup Strategy**: Configure MongoDB backups
4. **Monitoring**: Set up alerts in Grafana
5. **Scaling**: Adjust node group size based on usage

## Recent Updates (2024)

### Monitoring Stack Enhancements
- **Added Loki**: Log aggregation system for centralized logging
- **Added Tempo**: Distributed tracing system for observability
- **Updated Grafana**: Enhanced with new datasources and dashboards
- **Updated Prometheus Stack**: Upgraded to version 52.0.0 for better compatibility

### Dashboard Improvements
- **RocketChat Dashboards**: Added specialized monitoring dashboards
- **Community Dashboards**: Integrated popular Kubernetes monitoring dashboards
- **Automatic Provisioning**: All dashboards are now automatically imported

### Azure Sandbox Support
- **Sandbox Compatibility**: Added support for Azure sandbox environments
- **Resource Limits**: Configured to respect sandbox limitations (3 clusters, 3 nodes)
- **Authentication**: Added service principal authentication support

## Troubleshooting

See [troubleshooting.md](./troubleshooting.md) for common issues and solutions.

## Clean Up

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will permanently delete all data and resources!
