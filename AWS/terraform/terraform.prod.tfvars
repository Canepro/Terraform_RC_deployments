# ========================================
# AWS Production Environment Configuration
# ========================================
# Usage: terraform apply -var-file=terraform.prod.tfvars

# Deployment Identifier (REQUIRED - must be unique per deployment)
deployment_id = "prod-001"

# AWS Configuration
aws_region = "us-east-1"
project_name = "rocketchat-eks"
environment = "production"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# EKS Configuration - Production sizing (full resources)
eks_cluster_version = "1.28"
node_instance_types = ["t3.large"]  # Larger instances for production
node_desired_size = 3
node_min_size = 3  # Maintain minimum availability
node_max_size = 6  # Allow scaling for high load

# RocketChat Configuration - Full redundancy
rocketchat_replicas = 3  # High availability
mongodb_replicas = 3     # Replica set

# Tags
tags = {
  Project      = "RocketChat"
  Environment  = "Production"
  ManagedBy    = "Terraform"
  DeploymentID = "prod-001"
}

