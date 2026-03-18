###############################################################################
# EKS Module
# Creates EKS Cluster with Managed Node Groups and OIDC Provider for IRSA
###############################################################################

# ---------- EKS Cluster IAM Role ----------

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.project_name}-${var.environment}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_cluster.name
}

# ---------- EKS Cluster ----------

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    security_group_ids      = [var.cluster_security_group_id]
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
  }

  enabled_cluster_log_types = var.enabled_log_types

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = merge(var.common_tags, {
    Name = var.cluster_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
  ]
}

# ---------- EKS Add-ons ----------

resource "aws_eks_addon" "this" {
  for_each = {
    coredns            = { addon_version = null, resolve_conflicts = "OVERWRITE", service_account_role_arn = null }
    kube-proxy         = { addon_version = null, resolve_conflicts = "OVERWRITE", service_account_role_arn = null }
    vpc-cni            = { addon_version = null, resolve_conflicts = "OVERWRITE", service_account_role_arn = null }
    aws-ebs-csi-driver = { addon_version = null, resolve_conflicts = "OVERWRITE", service_account_role_arn = aws_iam_role.irsa["ebs_csi"].arn }
  }

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  service_account_role_arn    = each.value.service_account_role_arn
  resolve_conflicts_on_update = each.value.resolve_conflicts

  depends_on = [aws_eks_node_group.this]
}

# ---------- Node Group IAM Role ----------

data "aws_iam_policy_document" "node_group_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node_group" {
  name               = "${var.project_name}-${var.environment}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_group_assume_role.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "node_group" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  policy_arn = each.value
  role       = aws_iam_role.node_group.name
}

# ---------- Managed Node Groups ----------

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-${var.environment}-${each.key}-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = merge({
    Environment = var.environment
    NodeGroup   = each.key
  }, each.value.labels)

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-${each.key}-node"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_group,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ---------- OIDC Provider for IRSA ----------

data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.eks.certificates[*].sha1_fingerprint
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-oidc"
  })
}

# ---------- Moved Blocks (State Migration) ----------

moved {
  from = aws_iam_role_policy_attachment.eks_cluster_policy
  to   = aws_iam_role_policy_attachment.eks_cluster["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
}

moved {
  from = aws_iam_role_policy_attachment.eks_vpc_resource_controller
  to   = aws_iam_role_policy_attachment.eks_cluster["arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"]
}

moved {
  from = aws_eks_addon.coredns
  to   = aws_eks_addon.this["coredns"]
}

moved {
  from = aws_eks_addon.kube_proxy
  to   = aws_eks_addon.this["kube-proxy"]
}

moved {
  from = aws_eks_addon.vpc_cni
  to   = aws_eks_addon.this["vpc-cni"]
}

moved {
  from = aws_eks_addon.ebs_csi_driver
  to   = aws_eks_addon.this["aws-ebs-csi-driver"]
}

moved {
  from = aws_iam_role_policy_attachment.node_worker_policy
  to   = aws_iam_role_policy_attachment.node_group["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]
}

moved {
  from = aws_iam_role_policy_attachment.node_cni_policy
  to   = aws_iam_role_policy_attachment.node_group["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]
}

moved {
  from = aws_iam_role_policy_attachment.node_ecr_readonly
  to   = aws_iam_role_policy_attachment.node_group["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
}

moved {
  from = aws_iam_role_policy_attachment.node_ssm_managed
  to   = aws_iam_role_policy_attachment.node_group["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

moved {
  from = aws_eks_node_group.this
  to   = aws_eks_node_group.this["initial"]
}

# ---------- Cluster Access Entries ----------

resource "aws_eks_access_entry" "admin" {
  for_each      = toset(var.admin_user_arns)
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  for_each      = toset(var.admin_user_arns)
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}
