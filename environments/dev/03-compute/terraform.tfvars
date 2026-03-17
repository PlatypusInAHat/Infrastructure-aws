###############################################################################
# Layer 03-compute - Dev tfvars
###############################################################################

region       = "ap-southeast-1"
project_name = "lab-aws"
environment  = "dev"

# Remote state bucket (replace ACCOUNT_ID)
state_bucket = "lab-aws-terraform-state-361183471902"

# EKS - Smaller footprint for dev
eks_cluster_version        = "1.29"
eks_endpoint_public_access = true
eks_node_groups = {
  initial = {
    instance_types = ["c7i-flex.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 30
    desired_size   = 2
    min_size       = 2
    max_size       = 5
    labels         = { NodeGroup = "initial" }
  }
}

# Application
eks_enabled_log_types      = ["api", "audit", "authenticator"]
app_namespace              = "sample-app"
app_service_account_name   = "app-sa"
