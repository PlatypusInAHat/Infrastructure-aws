###############################################################################
# Layer 03-compute - Main
# Deploys EKS Cluster, Managed Node Groups, IRSA
# Reads from Layer 01-network (subnets) and Layer 02-security (SGs)
###############################################################################

locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"

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

# ---------- EKS ----------

module "eks" {
  source = "../../../modules/eks"

  project_name              = var.project_name
  environment               = var.environment
  cluster_name              = local.cluster_name
  cluster_version           = var.eks_cluster_version
  private_subnet_ids        = data.terraform_remote_state.network.outputs.private_subnet_ids
  public_subnet_ids         = data.terraform_remote_state.network.outputs.public_subnet_ids
  cluster_security_group_id = data.terraform_remote_state.security.outputs.eks_cluster_security_group_id
  endpoint_public_access    = var.eks_endpoint_public_access
  enabled_log_types         = var.eks_enabled_log_types
  node_instance_types       = var.eks_node_instance_types
  node_capacity_type        = var.eks_node_capacity_type
  node_disk_size            = var.eks_node_disk_size
  node_desired_size         = var.eks_node_desired_size
  node_min_size             = var.eks_node_min_size
  node_max_size             = var.eks_node_max_size
  app_namespace             = var.app_namespace
  app_service_account_name  = var.app_service_account_name
  common_tags               = local.common_tags
}
