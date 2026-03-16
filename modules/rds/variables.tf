variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling in GB"
  type        = number
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "database_username" {
  description = "Master username for the database"
  type        = string
}

variable "database_port" {
  description = "Database port"
  type        = number
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
}

variable "rds_security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
