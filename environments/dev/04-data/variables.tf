###############################################################################
# Layer 04-data - Variables
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
}

variable "rds_max_allocated_storage" {
  description = "RDS max allocated storage for autoscaling"
  type        = number
}

variable "rds_storage_type" {
  description = "RDS storage type (gp2, gp3, io1)"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_username" {
  description = "Database master username"
  type        = string
}

variable "database_port" {
  description = "Database port"
  type        = number
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ"
  type        = bool
}

variable "rds_backup_retention_period" {
  description = "Backup retention in days"
  type        = number
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
}

variable "rds_performance_insights" {
  description = "Enable RDS Performance Insights"
  type        = bool
}

variable "rds_backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
}

variable "rds_maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
}

variable "rds_parameters" {
  description = "A list of DB parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
