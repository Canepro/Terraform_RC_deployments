variable "deployment_id" {
  description = "Unique deployment identifier for deterministic resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,16}$", var.deployment_id))
    error_message = "deployment_id must be 3-16 characters, lowercase alphanumeric and hyphens only"
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "rocketchat-eks"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "rocketchat_replicas" {
  description = "Number of RocketChat replicas"
  type        = number
  default     = 2
}

variable "mongodb_replicas" {
  description = "Number of MongoDB replicas"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "RocketChat"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
