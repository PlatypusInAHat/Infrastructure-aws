###############################################################################
# Layer 02-security - Main
# Deploys Security Groups for ALB, EKS, and RDS
# Reads VPC ID from Layer 01-network via remote state
###############################################################################

locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ---------- Read Layer 01-network state ----------

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "environments/${var.environment}/01-network/terraform.tfstate"
    region = var.region
  }
}

# ---------- Security Groups ----------

module "security" {
  source = "../../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = data.terraform_remote_state.network.outputs.vpc_id
  cluster_name = local.cluster_name
  db_port      = var.db_port
  common_tags  = local.common_tags
}
