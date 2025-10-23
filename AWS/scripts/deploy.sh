#!/bin/bash

# RocketChat EKS Deployment Script
# This script automates the deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    cd terraform
    terraform init
    print_success "Terraform initialized successfully!"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_success "Terraform plan created successfully!"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    print_warning "This will create AWS resources. Estimated cost: ~$150-200/month"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply tfplan
        print_success "Terraform deployment completed successfully!"
    else
        print_warning "Deployment cancelled by user."
        exit 0
    fi
}

# Configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl..."
    CLUSTER_NAME=$(terraform output -raw cluster_id)
    REGION=$(terraform output -raw aws_region)
    
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    
    # Verify cluster access
    kubectl get nodes
    print_success "kubectl configured successfully!"
}

# Wait for cluster to be ready
wait_for_cluster() {
    print_status "Waiting for cluster to be ready..."
    
    # Wait for nodes to be ready
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Wait for system pods to be ready
    kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s
    
    print_success "Cluster is ready!"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check all namespaces
    kubectl get namespaces
    
    # Check RocketChat pods
    kubectl get pods -n rocketchat
    
    # Check monitoring pods
    kubectl get pods -n monitoring
    
    # Check services
    kubectl get services --all-namespaces
    
    # Check ingress
    kubectl get ingress --all-namespaces
    
    print_success "Deployment verification completed!"
}

# Get access information
get_access_info() {
    print_status "Getting access information..."
    
    ALB_DNS=$(terraform output -raw alb_dns_name)
    S3_BUCKET=$(terraform output -raw s3_bucket_id)
    
    echo ""
    echo "=========================================="
    echo "🚀 RocketChat EKS Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "📱 RocketChat URL: http://$ALB_DNS"
    echo "📊 Grafana URL: http://$ALB_DNS/grafana"
    echo "🪣 S3 Bucket: $S3_BUCKET"
    echo ""
    echo "🔐 Default Credentials:"
    echo "   Grafana: admin / admin123"
    echo "   RocketChat: Check pod logs for admin credentials"
    echo ""
    echo "📚 Documentation: ../DOCs/"
    echo "   - deployment.md: Deployment guide"
    echo "   - troubleshooting.md: Common issues"
    echo "   - architecture.md: Architecture overview"
    echo "   - operations.md: Day-2 operations"
    echo ""
    echo "🧹 To clean up: terraform destroy"
    echo "=========================================="
}

# Main deployment function
main() {
    echo "🚀 Starting RocketChat EKS Deployment..."
    echo ""
    
    check_prerequisites
    init_terraform
    plan_terraform
    apply_terraform
    configure_kubectl
    wait_for_cluster
    verify_deployment
    get_access_info
    
    print_success "🎉 Deployment completed successfully!"
}

# Run main function
main "$@"
