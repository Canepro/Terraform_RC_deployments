#!/bin/bash

# Azure RocketChat Deployment Script
set -e

echo "🚀 Starting Azure RocketChat Deployment..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    echo "   Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    echo "   Visit: https://www.terraform.io/downloads.html"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    echo "   Visit: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install it first."
    echo "   Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi

echo "✅ All required tools are installed"

# Login to Azure
echo "🔐 Logging into Azure..."
az login

# Set subscription (optional - uncomment and modify if needed)
# echo "📋 Setting Azure subscription..."
# az account set --subscription "your-subscription-id"

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "📋 Using subscription: $SUBSCRIPTION_ID"

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -out=azure.tfplan

# Apply deployment
echo "🚀 Applying deployment..."
terraform apply azure.tfplan

# Get outputs
echo "📊 Getting deployment outputs..."
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
APP_GATEWAY_IP=$(terraform output -raw app_gateway_public_ip)

echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Deployment Information:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  AKS Cluster: $CLUSTER_NAME"
echo "  Application Gateway IP: $APP_GATEWAY_IP"
echo ""
echo "🔧 Next steps:"
echo "  1. Configure kubectl: az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME"
echo "  2. Access RocketChat: http://$APP_GATEWAY_IP"
echo "  3. Access Grafana: http://$APP_GATEWAY_IP/grafana"
echo ""
echo "📚 For more information, see the documentation in the DOCs folder."
