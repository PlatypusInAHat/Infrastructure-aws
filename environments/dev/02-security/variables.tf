###############################################################################
# Layer 02-security - Variables
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

variable "state_bucket" {
  description = "S3 bucket name for remote state"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
}
