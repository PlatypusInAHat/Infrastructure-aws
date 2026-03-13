###############################################################################
# Layer 04-data - Main
# Deploys RDS PostgreSQL
# Reads from Layer 01-network (subnets) and Layer 02-security (SGs)
###############################################################################

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ---------- Read upstream layer states ----------

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "environments/${var.environment}/01-network/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "environments/${var.environment}/02-security/terraform.tfstate"
    region = var.region
  }
}

# ---------- RDS ----------

module "rds" {
  source = "../../../modules/rds"

  project_name                 = var.project_name
  environment                  = var.environment
  engine_version               = var.rds_engine_version
  instance_class               = var.rds_instance_class
  allocated_storage            = var.rds_allocated_storage
  max_allocated_storage        = var.rds_max_allocated_storage
  database_name                = var.database_name
  database_username            = var.database_username
  database_port                = var.database_port
  db_subnet_group_name         = data.terraform_remote_state.network.outputs.db_subnet_group_name
  rds_security_group_id        = data.terraform_remote_state.security.outputs.rds_security_group_id
  multi_az                     = var.rds_multi_az
  backup_retention_period      = var.rds_backup_retention_period
  deletion_protection          = var.rds_deletion_protection
  skip_final_snapshot          = var.rds_skip_final_snapshot
  performance_insights_enabled = var.rds_performance_insights
  common_tags                  = local.common_tags
}
# ---------- Secrets Manager (for GitHub Token) ----------

resource "aws_secretsmanager_secret" "github_token" {
  name        = "${var.project_name}-${var.environment}-github-token"
  description = "GitHub Personal Access Token for ArgoCD"
  
  recovery_window_in_days = 0 # Force delete for lab environment
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-github-token"
  })
}

output "github_token_secret_arn" {
  value       = aws_secretsmanager_secret.github_token.arn
  description = "The ARN of the GitHub token secret"
}
