# ========================================
# AWS Sandbox Environment Configuration
# ========================================
# Usage: terraform apply -var-file=terraform.sandbox.tfvars

# Deployment Identifier (REQUIRED - must be unique per deployment)
deployment_id = "sandbox-001"

# AWS Configuration
aws_region = "us-east-1"
project_name = "rocketchat-eks"
environment = "sandbox"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# EKS Configuration - Sandbox sizing (minimal resources)
eks_cluster_version = "1.28"
node_instance_types = ["t3.small"]  # Smaller instance for sandbox
node_desired_size = 2
node_min_size = 2
node_max_size = 3  # Limited scaling for sandbox

# RocketChat Configuration - Minimal replicas
rocketchat_replicas = 1  # Single replica for sandbox
mongodb_replicas = 1     # Single replica for sandbox

# Tags
tags = {
  Project      = "RocketChat"
  Environment  = "Sandbox"
  ManagedBy    = "Terraform"
  DeploymentID = "sandbox-001"
}

