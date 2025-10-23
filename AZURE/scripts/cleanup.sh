#!/bin/bash

# Azure RocketChat Cleanup Script
set -e

echo "🧹 Starting Azure RocketChat Cleanup..."

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Get outputs before cleanup
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)

echo "📋 Resources to be destroyed:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  AKS Cluster: $CLUSTER_NAME"
echo ""

# Confirm cleanup
read -p "⚠️  Are you sure you want to destroy all resources? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

# Destroy resources
echo "🗑️  Destroying resources..."
terraform destroy -auto-approve

echo "✅ Cleanup completed successfully!"
echo ""
echo "📋 All resources have been destroyed:"
echo "  - AKS Cluster"
echo "  - Application Gateway"
echo "  - Storage Accounts"
echo "  - Virtual Network"
echo "  - Resource Group"
echo ""
echo "💡 Note: Some resources may take a few minutes to be fully deleted."
