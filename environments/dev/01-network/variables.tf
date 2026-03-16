###############################################################################
# Layer 01-network - Variables
###############################################################################

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones"
  type        = number
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cost savings)"
  type        = bool
}
