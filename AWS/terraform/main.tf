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
  
  common_tags = merge(var.tags, {
    Name = local.name
  })
}
