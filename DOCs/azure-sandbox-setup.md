# Azure Sandbox Setup Guide

## Prerequisites

You need:
1. Azure sandbox credentials (service principal)
2. Resource group name from your sandbox environment

---

## Step 1: Find Your Sandbox Resource Group

```bash
# Login with service principal
az login --service-principal \
  --username <CLIENT_ID> \
  --password <CLIENT_SECRET> \
  --tenant <TENANT_ID>

# List all resource groups
az group list --query "[].name" -o tsv

# Find sandbox RG (usually ends with "playground-sandbox")
az group list --query "[?contains(name, 'playground-sandbox')].name" -o tsv
```

**Example output**:
```
1-bb26fa15-playground-sandbox
```

---

## Step 2: Set Up Terraform Credentials

Create `AZURE/terraform/.azure-credentials.sh`:

```bash
#!/bin/bash
export ARM_CLIENT_ID="<YOUR_CLIENT_ID>"
export ARM_CLIENT_SECRET="<YOUR_CLIENT_SECRET>"
export ARM_TENANT_ID="<YOUR_TENANT_ID>"
export ARM_SUBSCRIPTION_ID="<YOUR_SUBSCRIPTION_ID>"

echo "✅ Azure credentials exported for Terraform"
```

Make it executable:
```bash
chmod +x AZURE/terraform/.azure-credentials.sh
```

**Note**: This file is gitignored—never commit credentials!

---

## Step 3: Configure terraform.tfvars

Copy the example and set your RG name:

```bash
cd AZURE/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
deployment_id = "sandbox01"

# Set to YOUR sandbox RG name from Step 1
resource_group_name = "1-bb26fa15-playground-sandbox"
create_resource_group = false

# Rest of config...
```

---

## Step 4: Initialize and Deploy

```bash
# Export credentials
source .azure-credentials.sh

# Initialize Terraform
terraform init -upgrade

# Plan deployment
terraform plan -var="deployment_id=sandbox01" -out aks.tfplan

# Review the plan, then apply
terraform apply aks.tfplan
```

---

## Common Issues

### Error: AuthorizationFailed

**Symptom**:
```
The client does not have authorization to perform action 'Microsoft.Resources/subscriptions/resourcegroups/read'
```

**Cause**: `resource_group_name` is empty or incorrect.

**Fix**:
1. Run: `az group list --query "[].name" -o tsv | grep sandbox`
2. Copy the exact RG name to `terraform.tfvars`
3. Ensure `create_resource_group = false`

### Error: Could not auto-discover sandbox resource group

**Symptom**:
```
Could not auto-discover sandbox resource group. Please set resource_group_name...
```

**Cause**: Auto-discovery found no RG matching `*playground-sandbox` pattern.

**Fix**: Set `resource_group_name` explicitly in `terraform.tfvars`.

---

## Cleanup

```bash
# Destroy all resources
terraform plan -destroy -var="deployment_id=sandbox01" -out destroy.tfplan
terraform apply destroy.tfplan
```

**Important**: Sandbox RG itself won't be deleted (we don't own it), only resources inside it.

---

## Reference

- [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) - Full deployment guide
- [PHASE-A-SUMMARY.md](PHASE-A-SUMMARY.md) - Phase A changes
- [troubleshooting-azure.md](troubleshooting-azure.md) - Azure issues

