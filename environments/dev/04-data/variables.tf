###############################################################################
# Layer 04-data - Variables
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
  default     = "lab-aws-terraform-state-361183471902"
  description = "S3 bucket name for remote state"
  type        = string
}

# ---------- RDS ----------

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "RDS max allocated storage for autoscaling"
  type        = number
  default     = 50
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "database_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "database_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 1
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = true
}

variable "rds_performance_insights" {
  description = "Enable RDS Performance Insights"
  type        = bool
  default     = false
}
