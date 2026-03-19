###############################################################################
# Security Groups Module
# Least-privilege security groups for EKS, RDS, and ALB
###############################################################################

# ---------- ALB Security Group ----------

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- EKS Cluster Security Group ----------

resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-${var.environment}-eks-cluster-"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- EKS Nodes Security Group ----------

resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-${var.environment}-eks-nodes-"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name                                        = "${var.project_name}-${var.environment}-eks-nodes-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- RDS Security Group ----------

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- Security Group Rules Mapping ----------

data "aws_security_groups" "eks_managed" {
  filter {
    name   = "tag:kubernetes.io/cluster/${var.cluster_name}"
    values = ["owned"]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

locals {
  # Use the first managed SG found (EKS always creates one)
  eks_managed_sg_id = length(data.aws_security_groups.eks_managed.ids) > 0 ? data.aws_security_groups.eks_managed.ids[0] : null

  rules = {
    # ALB Rules
    alb_http = {
      sg_id       = aws_security_group.alb.id
      type        = "ingress"
      from        = 80
      to          = 80
      proto       = "tcp"
      cidr        = ["0.0.0.0/0"]
      description = "Allow HTTP from internet"
    }
    alb_https = {
      sg_id       = aws_security_group.alb.id
      type        = "ingress"
      from        = 443
      to          = 443
      proto       = "tcp"
      cidr        = ["0.0.0.0/0"]
      description = "Allow HTTPS from internet"
    }
    alb_to_nodes = {
      sg_id       = aws_security_group.alb.id
      type        = "egress"
      from        = 0
      to          = 65535
      proto       = "tcp"
      source_sg   = aws_security_group.eks_nodes.id
      description = "Allow traffic to EKS nodes"
    }

    # EKS Cluster Rules
    cluster_from_nodes = {
      sg_id       = aws_security_group.eks_cluster.id
      type        = "ingress"
      from        = 443
      to          = 443
      proto       = "tcp"
      source_sg   = aws_security_group.eks_nodes.id
      description = "Allow HTTPS from worker nodes"
    }
    cluster_to_nodes_all = {
      sg_id       = aws_security_group.eks_cluster.id
      type        = "egress"
      from        = 1025
      to          = 65535
      proto       = "tcp"
      source_sg   = aws_security_group.eks_nodes.id
      description = "Allow traffic to worker nodes"
    }
    cluster_to_nodes_https = {
      sg_id       = aws_security_group.eks_cluster.id
      type        = "egress"
      from        = 443
      to          = 443
      proto       = "tcp"
      source_sg   = aws_security_group.eks_nodes.id
      description = "Allow HTTPS to worker nodes"
    }

    # EKS Nodes Rules
    nodes_internal = {
      sg_id       = aws_security_group.eks_nodes.id
      type        = "ingress"
      from        = 0
      to          = 65535
      proto       = "-1"
      source_sg   = aws_security_group.eks_nodes.id
      description = "Allow node-to-node communication"
    }
    nodes_from_cluster = {
      sg_id       = aws_security_group.eks_nodes.id
      type        = "ingress"
      from        = 1025
      to          = 65535
      proto       = "tcp"
      source_sg   = aws_security_group.eks_cluster.id
      description = "Allow traffic from control plane"
    }
    nodes_from_cluster_https = {
      sg_id       = aws_security_group.eks_nodes.id
      type        = "ingress"
      from        = 443
      to          = 443
      proto       = "tcp"
      source_sg   = aws_security_group.eks_cluster.id
      description = "Allow HTTPS from control plane"
    }
    nodes_from_alb = {
      sg_id       = aws_security_group.eks_nodes.id
      type        = "ingress"
      from        = 0
      to          = 65535
      proto       = "tcp"
      source_sg   = aws_security_group.alb.id
      description = "Allow traffic from ALB"
    }
    nodes_egress_all = {
      sg_id       = aws_security_group.eks_nodes.id
      type        = "egress"
      from        = 0
      to          = 0
      proto       = "-1"
      cidr        = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }

    # RDS Rules
    rds_from_nodes = {
      sg_id       = aws_security_group.rds.id
      type        = "ingress"
      from        = var.db_port
      to          = var.db_port
      proto       = "tcp"
      source_sg   = aws_security_group.eks_nodes.id
      description = "Allow database access from EKS nodes"
    }
    rds_from_cluster = {
      sg_id       = aws_security_group.rds.id
      type        = "ingress"
      from        = var.db_port
      to          = var.db_port
      proto       = "tcp"
      source_sg   = aws_security_group.eks_cluster.id
      description = "Allow database access from EKS cluster managed SG"
    }
    rds_from_cluster_managed = {
      sg_id       = aws_security_group.rds.id
      type        = "ingress"
      from        = var.db_port
      to          = var.db_port
      proto       = "tcp"
      source_sg   = local.eks_managed_sg_id
      description = "Allow database access from EKS-managed cluster SG"
    }
  }
}

resource "aws_security_group_rule" "rules" {
  for_each = local.rules

  security_group_id = each.value.sg_id
  type              = each.value.type
  from_port         = each.value.from
  to_port           = each.value.to
  protocol          = each.value.proto
  description       = each.value.description

  cidr_blocks              = lookup(each.value, "cidr", null)
  source_security_group_id = lookup(each.value, "source_sg", null)
}

# ---------- Moved blocks for state migration ----------

moved {
  from = aws_security_group_rule.alb_ingress_http
  to   = aws_security_group_rule.rules["alb_http"]
}

moved {
  from = aws_security_group_rule.alb_ingress_https
  to   = aws_security_group_rule.rules["alb_https"]
}

moved {
  from = aws_security_group_rule.alb_egress_to_nodes
  to   = aws_security_group_rule.rules["alb_to_nodes"]
}

moved {
  from = aws_security_group_rule.cluster_ingress_from_nodes
  to   = aws_security_group_rule.rules["cluster_from_nodes"]
}

moved {
  from = aws_security_group_rule.cluster_egress_to_nodes
  to   = aws_security_group_rule.rules["cluster_to_nodes_all"]
}

moved {
  from = aws_security_group_rule.cluster_egress_to_nodes_https
  to   = aws_security_group_rule.rules["cluster_to_nodes_https"]
}

moved {
  from = aws_security_group_rule.nodes_internal
  to   = aws_security_group_rule.rules["nodes_internal"]
}

moved {
  from = aws_security_group_rule.nodes_ingress_from_cluster
  to   = aws_security_group_rule.rules["nodes_from_cluster"]
}

moved {
  from = aws_security_group_rule.nodes_ingress_from_cluster_https
  to   = aws_security_group_rule.rules["nodes_from_cluster_https"]
}

moved {
  from = aws_security_group_rule.nodes_ingress_from_alb
  to   = aws_security_group_rule.rules["nodes_from_alb"]
}

moved {
  from = aws_security_group_rule.nodes_egress
  to   = aws_security_group_rule.rules["nodes_egress_all"]
}

moved {
  from = aws_security_group_rule.rds_ingress_from_nodes
  to   = aws_security_group_rule.rules["rds_from_nodes"]
}
