# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# Local values for common configurations
locals {
  name = "${var.project_name}-${var.environment}"
  
  # Deterministic naming based on deployment_id
  deployment_id_sanitized = lower(replace(var.deployment_id, "/[^a-z0-9-]/", ""))
  
  # S3 bucket names (3-63 chars, lowercase, no underscores, globally unique)
  s3_bucket_name = substr("${local.deployment_id_sanitized}-rc-files-${var.aws_region}", 0, 63)
  
  # EKS cluster name
  eks_cluster_name = "${local.deployment_id_sanitized}-eks"
  
  common_tags = merge(var.tags, {
    Name         = local.name
    DeploymentID = var.deployment_id
  })
}
