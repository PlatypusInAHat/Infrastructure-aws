###############################################################################
# Layer 02-security - Variables
###############################################################################

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "lab-aws"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "state_bucket" {
  description = "S3 bucket name for remote state"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}
