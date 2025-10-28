# ========================================
# AWS Development Environment Configuration
# ========================================
# Usage: terraform apply -var-file=terraform.dev.tfvars

# Deployment Identifier (REQUIRED - must be unique per deployment)
deployment_id = "dev-001"

# AWS Configuration
aws_region = "us-east-1"
project_name = "rocketchat-eks"
environment = "development"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# EKS Configuration - Dev sizing (moderate resources)
eks_cluster_version = "1.28"
node_instance_types = ["t3.medium"]
node_desired_size = 2
node_min_size = 1  # Can scale down to save costs
node_max_size = 3

# RocketChat Configuration
rocketchat_replicas = 2
mongodb_replicas = 3

# Tags
tags = {
  Project      = "RocketChat"
  Environment  = "Development"
  ManagedBy    = "Terraform"
  DeploymentID = "dev-001"
}

