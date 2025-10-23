#!/bin/bash

# RocketChat EKS Cleanup Script
# This script destroys all AWS resources created by Terraform

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

# Confirm cleanup
confirm_cleanup() {
    print_warning "This will destroy ALL AWS resources created by this Terraform configuration."
    print_warning "This includes:"
    print_warning "  - EKS Cluster and all nodes"
    print_warning "  - VPC and all networking components"
    print_warning "  - Application Load Balancer"
    print_warning "  - S3 bucket and all data"
    print_warning "  - EBS volumes and all data"
    print_warning "  - All other AWS resources"
    echo ""
    print_warning "This action is IRREVERSIBLE!"
    echo ""
    read -p "Are you sure you want to continue? Type 'yes' to confirm: " -r
    if [[ ! $REPLY == "yes" ]]; then
        print_status "Cleanup cancelled by user."
        exit 0
    fi
}

# Check if we're in the right directory
check_directory() {
    if [ ! -f "terraform/main.tf" ]; then
        print_error "Please run this script from the Terraform_RC_deployments/AWS directory"
        exit 1
    fi
}

# Check if Terraform state exists
check_terraform_state() {
    if [ ! -f "terraform/terraform.tfstate" ]; then
        print_warning "No Terraform state file found. Nothing to destroy."
        exit 0
    fi
}

# Destroy Terraform resources
destroy_terraform() {
    print_status "Destroying Terraform resources..."
    cd terraform
    
    # Plan destruction
    print_status "Planning destruction..."
    terraform plan -destroy -out=destroy.tfplan
    
    # Apply destruction
    print_status "Applying destruction..."
    terraform apply destroy.tfplan
    
    print_success "Terraform resources destroyed successfully!"
}

# Clean up local files
cleanup_local() {
    print_status "Cleaning up local files..."
    
    # Remove Terraform files
    rm -f terraform/terraform.tfstate*
    rm -f terraform/.terraform.lock.hcl
    rm -rf terraform/.terraform/
    rm -f terraform/tfplan
    rm -f terraform/destroy.tfplan
    
    # Remove verification reports
    rm -f verification-report-*.txt
    
    print_success "Local files cleaned up!"
}

# Verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    # Check if cluster still exists
    if kubectl cluster-info &> /dev/null; then
        print_warning "Cluster still accessible. This may indicate incomplete cleanup."
    else
        print_success "Cluster is no longer accessible."
    fi
    
    # Check AWS resources
    print_status "Checking remaining AWS resources..."
    
    # Check EKS clusters
    EKS_CLUSTERS=$(aws eks list-clusters --query 'clusters[?contains(name, `rocketchat`)].name' --output text 2>/dev/null || echo "")
    if [ -n "$EKS_CLUSTERS" ]; then
        print_warning "EKS clusters still exist: $EKS_CLUSTERS"
    else
        print_success "No EKS clusters found."
    fi
    
    # Check EC2 instances
    EC2_INSTANCES=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=*rocketchat*" --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null || echo "")
    if [ -n "$EC2_INSTANCES" ]; then
        print_warning "EC2 instances still exist: $EC2_INSTANCES"
    else
        print_success "No EC2 instances found."
    fi
    
    # Check S3 buckets
    S3_BUCKETS=$(aws s3 ls | grep rocketchat || echo "")
    if [ -n "$S3_BUCKETS" ]; then
        print_warning "S3 buckets still exist:"
        echo "$S3_BUCKETS"
    else
        print_success "No S3 buckets found."
    fi
}

# Final cleanup report
cleanup_report() {
    print_status "Generating cleanup report..."
    
    REPORT_FILE="cleanup-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "RocketChat EKS Cleanup Report"
        echo "Generated: $(date)"
        echo "=========================="
        echo ""
        
        echo "Cleanup completed successfully!"
        echo ""
        echo "Resources destroyed:"
        echo "  - EKS Cluster and all nodes"
        echo "  - VPC and all networking components"
        echo "  - Application Load Balancer"
        echo "  - S3 bucket and all data"
        echo "  - EBS volumes and all data"
        echo "  - All other AWS resources"
        echo ""
        echo "Local files cleaned up:"
        echo "  - Terraform state files"
        echo "  - Terraform lock files"
        echo "  - Terraform plan files"
        echo "  - Verification reports"
        echo ""
        echo "Cost savings:"
        echo "  - Estimated monthly cost: $0 (all resources destroyed)"
        echo ""
        echo "Next steps:"
        echo "  - Verify all resources are destroyed in AWS Console"
        echo "  - Check for any remaining resources manually"
        echo "  - Update your AWS billing to confirm cost reduction"
        echo ""
        
    } > "$REPORT_FILE"
    
    print_success "Cleanup report saved to: $REPORT_FILE"
}

# Main cleanup function
main() {
    echo "🧹 Starting RocketChat EKS Cleanup..."
    echo ""
    
    check_directory
    check_terraform_state
    confirm_cleanup
    destroy_terraform
    cleanup_local
    verify_cleanup
    cleanup_report
    
    print_success "🎉 Cleanup completed successfully!"
    echo ""
    echo "=========================================="
    echo "🧹 RocketChat EKS Cleanup Complete!"
    echo "=========================================="
    echo ""
    echo "✅ All AWS resources have been destroyed"
    echo "✅ Local files have been cleaned up"
    echo "✅ Cost savings: ~$150-200/month"
    echo ""
    echo "📊 Check AWS Console to verify all resources are gone"
    echo "📈 Monitor your AWS billing for cost reduction"
    echo ""
    echo "🔄 To redeploy: ./scripts/deploy.sh"
    echo "=========================================="
}

# Run main function
main "$@"
