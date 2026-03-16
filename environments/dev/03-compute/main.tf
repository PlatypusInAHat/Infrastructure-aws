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

# ---------- Kubernetes Namespaces ----------

resource "kubernetes_namespace" "this" {
  for_each = toset(["external-secrets"])
  metadata {
    name = each.value
  }
}

# ---------- Helm Releases & Service Accounts ----------

locals {
  helm_releases = {
    lb_controller = {
      name            = "aws-load-balancer-controller"
      repository      = "https://aws.github.io/eks-charts"
      chart           = "aws-load-balancer-controller"
      version         = "1.7.1"
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
      role_arn        = module.eks.lb_controller_role_arn
      values = {
        clusterName = module.eks.cluster_name
        region      = var.region
        vpcId       = data.terraform_remote_state.network.outputs.vpc_id
      }
    }
    external_secrets = {
      name            = "external-secrets"
      repository      = "https://charts.external-secrets.io"
      chart           = "external-secrets"
      version         = "0.9.13"
      namespace       = "external-secrets"
      service_account = "external-secrets"
      role_arn        = module.eks.eso_role_arn
      values = {
        installCRDs = true
      }
    }
  }
}

resource "kubernetes_service_account" "this" {
  for_each = local.helm_releases

  metadata {
    name      = each.value.service_account
    namespace = each.value.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = each.value.role_arn
    }
  }

  depends_on = [kubernetes_namespace.this]
}

resource "helm_release" "this" {
  for_each = local.helm_releases

  name       = each.value.name
  repository = each.value.repository
  chart      = each.value.chart
  version    = each.value.version
  namespace  = each.value.namespace

  values = [
    yamlencode(merge(each.value.values, {
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.this[each.key].metadata[0].name
      }
    }))
  ]

  depends_on = [module.eks, kubernetes_service_account.this]
}

# ---------- Moved Blocks (State Migration) ----------

moved {
  from = kubernetes_service_account.lb_controller
  to   = kubernetes_service_account.this["lb_controller"]
}

moved {
  from = helm_release.lb_controller
  to   = helm_release.this["lb_controller"]
}

moved {
  from = kubernetes_namespace.eso
  to   = kubernetes_namespace.this["external-secrets"]
}

moved {
  from = helm_release.external_secrets
  to   = helm_release.this["external_secrets"]
}
