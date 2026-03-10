###############################################################################
# RDS Module
# Creates RDS PostgreSQL instance in database subnets
###############################################################################

locals {
  engine_major_version = split(".", var.engine_version)[0]
  engine_family        = "postgres${local.engine_major_version}"
}

resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ---------- RDS Instance ----------

resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.this.name

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true

  # Credentials
  db_name  = var.database_name
  username = var.database_username
  password = random_password.db_password.result

  # Network
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false
  port                   = var.database_port

  # High Availability
  multi_az = var.multi_az

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  # Protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-db-final-snapshot"

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-db"
  })
}

# ---------- Parameter Group ----------

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.project_name}-${var.environment}-${local.engine_family}-"
  family      = local.engine_family
  description = "Custom parameter group for ${var.project_name} ${var.environment}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-${local.engine_family}-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}
