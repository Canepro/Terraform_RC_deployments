variable "deployment_id" {
  description = "Unique deployment identifier for deterministic resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,16}$", var.deployment_id))
    error_message = "deployment_id must be 3-16 characters, lowercase alphanumeric and hyphens only"
  }
}

variable "azure_region" {
  description = "Azure region for deployment"
  type        = string
  default     = "East US"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "rocketchat-aks"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "resource_group_name" {
  description = "Name of the resource group (leave empty to auto-discover sandbox RG)"
  type        = string
  default     = ""
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = false
}

variable "vnet_cidr" {
  description = "CIDR block for VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_cluster_version" {
  description = "AKS cluster version"
  type        = string
  default     = "1.28"
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "min_count" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "max_count" {
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
