variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  type        = number

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "AZ count must be between 2 and 3."
  }
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway (cost savings for non-prod)"
  type        = bool
}

variable "cluster_name" {
  description = "EKS cluster name (for subnet tagging)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
