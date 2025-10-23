#!/bin/bash

# Azure RocketChat Deployment Verification Script
set -e

echo "🔍 Verifying Azure RocketChat Deployment..."

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Get outputs
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
APP_GATEWAY_IP=$(terraform output -raw app_gateway_public_ip)

echo "📋 Deployment Information:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  AKS Cluster: $CLUSTER_NAME"
echo "  Application Gateway IP: $APP_GATEWAY_IP"
echo ""

# Configure kubectl
echo "🔧 Configuring kubectl..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Check cluster status
echo "🔍 Checking AKS cluster status..."
kubectl cluster-info

# Check nodes
echo "🔍 Checking nodes..."
kubectl get nodes

# Check namespaces
echo "🔍 Checking namespaces..."
kubectl get namespaces

# Check RocketChat pods
echo "🔍 Checking RocketChat pods..."
kubectl get pods -n rocketchat

# Check monitoring pods
echo "🔍 Checking monitoring pods..."
kubectl get pods -n monitoring

# Check services
echo "🔍 Checking services..."
kubectl get services -n rocketchat
kubectl get services -n monitoring

# Check storage classes
echo "🔍 Checking storage classes..."
kubectl get storageclass

# Check persistent volumes
echo "🔍 Checking persistent volumes..."
kubectl get pv

# Test Application Gateway connectivity
echo "🔍 Testing Application Gateway connectivity..."
if curl -s --connect-timeout 10 http://$APP_GATEWAY_IP > /dev/null; then
    echo "✅ Application Gateway is responding"
else
    echo "⚠️  Application Gateway is not responding yet (this may take a few minutes)"
fi

echo ""
echo "🎉 Verification completed!"
echo ""
echo "📋 Access URLs:"
echo "  RocketChat: http://$APP_GATEWAY_IP"
echo "  Grafana: http://$APP_GATEWAY_IP/grafana"
echo ""
echo "🔧 Useful commands:"
echo "  kubectl get pods -n rocketchat"
echo "  kubectl get pods -n monitoring"
echo "  kubectl logs -n rocketchat -l app=rocketchat"
echo "  kubectl logs -n monitoring -l app.kubernetes.io/name=grafana"
