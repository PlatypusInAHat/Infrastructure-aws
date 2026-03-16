locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
  oidc_provider_url = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")

  irsa_configs = {
    ebs_csi = {
      role_name       = "ebs-csi-driver-role"
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
      policy_arns     = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
      inline_policy   = null
    }
    lb_controller = {
      role_name       = "lb-controller-role"
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
      policy_arns     = []
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect    = "Allow"
            Action    = ["iam:CreateServiceLinkedRole"]
            Resource  = "*"
            Condition = { StringEquals = { "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com" } }
          },
          {
            Effect = "Allow"
            Action = [
              "ec2:DescribeAccountAttributes", "ec2:DescribeAddresses", "ec2:DescribeAvailabilityZones",
              "ec2:DescribeInternetGateways", "ec2:DescribeVpcs", "ec2:DescribeVpcPeeringConnections",
              "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups", "ec2:DescribeInstances",
              "ec2:DescribeNetworkInterfaces", "ec2:DescribeTags", "ec2:GetCoipPoolUsage",
              "ec2:DescribeCoipPools", "elasticloadbalancing:DescribeLoadBalancers",
              "elasticloadbalancing:DescribeLoadBalancerAttributes", "elasticloadbalancing:DescribeListeners",
              "elasticloadbalancing:DescribeListenerCertificates", "elasticloadbalancing:DescribeSSLPolicies",
              "elasticloadbalancing:DescribeRules", "elasticloadbalancing:DescribeTargetGroups",
              "elasticloadbalancing:DescribeTargetGroupAttributes", "elasticloadbalancing:DescribeTargetHealth",
              "elasticloadbalancing:DescribeTags"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "cognito-idp:DescribeUserPoolClient", "acm:ListCertificates", "acm:DescribeCertificate",
              "iam:ListServerCertificates", "iam:GetServerCertificate", "waf-regional:GetWebACL",
              "waf-regional:GetWebACLForResource", "waf-regional:AssociateWebACL", "waf-regional:DisassociateWebACL",
              "wafv2:GetWebACL", "wafv2:GetWebACLForResource", "wafv2:AssociateWebACL", "wafv2:DisassociateWebACL",
              "shield:GetSubscriptionState", "shield:DescribeProtection", "shield:CreateProtection", "shield:DeleteProtection"
            ]
            Resource = "*"
          },
          {
            Effect   = "Allow"
            Action   = ["ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress", "ec2:CreateSecurityGroup", "ec2:CreateTags", "ec2:DeleteTags", "ec2:DeleteSecurityGroup"]
            Resource = "*"
          },
          {
            Effect   = "Allow"
            Action   = ["elasticloadbalancing:CreateLoadBalancer", "elasticloadbalancing:CreateTargetGroup"]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "elasticloadbalancing:CreateListener", "elasticloadbalancing:DeleteListener",
              "elasticloadbalancing:CreateRule", "elasticloadbalancing:DeleteRule",
              "elasticloadbalancing:AddTags", "elasticloadbalancing:RemoveTags",
              "elasticloadbalancing:ModifyLoadBalancerAttributes", "elasticloadbalancing:SetIpAddressType",
              "elasticloadbalancing:SetSecurityGroups", "elasticloadbalancing:SetSubnets",
              "elasticloadbalancing:DeleteLoadBalancer", "elasticloadbalancing:ModifyTargetGroup",
              "elasticloadbalancing:ModifyTargetGroupAttributes", "elasticloadbalancing:DeleteTargetGroup",
              "elasticloadbalancing:RegisterTargets", "elasticloadbalancing:DeregisterTargets",
              "elasticloadbalancing:SetWebACL", "elasticloadbalancing:ModifyListener", "elasticloadbalancing:ModifyRule"
            ]
            Resource = "*"
          }
        ]
      })
    }
    app = {
      role_name       = "app-role"
      namespace       = var.app_namespace
      service_account = var.app_service_account_name
      policy_arns     = []
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
            Resource = [
              "arn:aws:s3:::${var.project_name}-${var.environment}-*",
              "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
            ]
          },
          {
            Effect   = "Allow"
            Action   = ["rds-db:connect"]
            Resource = ["arn:aws:rds-db:*:*:dbuser:*/*"]
          }
        ]
      })
    }
    eso = {
      role_name       = "eso-role"
      namespace       = "external-secrets"
      service_account = "external-secrets"
      policy_arns     = []
      inline_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
            Resource = "*"
          }
        ]
      })
    }
  }
}

data "aws_iam_policy_document" "irsa_assume" {
  for_each = local.irsa_configs

  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  for_each = local.irsa_configs

  name               = "${var.project_name}-${var.environment}-${each.value.role_name}"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume[each.key].json
  tags               = var.common_tags
}

resource "aws_iam_policy" "irsa_inline" {
  for_each = { for k, v in local.irsa_configs : k => v if v.inline_policy != null }

  name        = "${var.project_name}-${var.environment}-${each.key}-policy"
  description = "Custom IAM policy for ${each.key}"
  policy      = each.value.inline_policy
  tags        = var.common_tags
}

resource "aws_iam_role_policy_attachment" "irsa_inline" {
  for_each = { for k, v in local.irsa_configs : k => v if v.inline_policy != null }

  policy_arn = aws_iam_policy.irsa_inline[each.key].arn
  role       = aws_iam_role.irsa[each.key].name
}

resource "aws_iam_role_policy_attachment" "irsa_managed" {
  for_each = { for item in flatten([
    for k, v in local.irsa_configs : [
      for p in v.policy_arns : {
        key        = "${k}-${p}"
        role_key   = k
        policy_arn = p
      }
    ]
  ]) : item.key => item }

  policy_arn = each.value.policy_arn
  role       = aws_iam_role.irsa[each.value.role_key].name
}

# ---------- Moved Blocks (State Migration) ----------

moved {
  from = aws_iam_role.ebs_csi_driver
  to   = aws_iam_role.irsa["ebs_csi"]
}

moved {
  from = aws_iam_role.lb_controller
  to   = aws_iam_role.irsa["lb_controller"]
}

moved {
  from = aws_iam_policy.lb_controller
  to   = aws_iam_policy.irsa_inline["lb_controller"]
}

moved {
  from = aws_iam_role_policy_attachment.lb_controller
  to   = aws_iam_role_policy_attachment.irsa_inline["lb_controller"]
}

moved {
  from = aws_iam_role.app
  to   = aws_iam_role.irsa["app"]
}

moved {
  from = aws_iam_policy.app
  to   = aws_iam_policy.irsa_inline["app"]
}

moved {
  from = aws_iam_role_policy_attachment.app
  to   = aws_iam_role_policy_attachment.irsa_inline["app"]
}

moved {
  from = aws_iam_role.eso
  to   = aws_iam_role.irsa["eso"]
}

moved {
  from = aws_iam_policy.eso
  to   = aws_iam_policy.irsa_inline["eso"]
}

moved {
  from = aws_iam_role_policy_attachment.eso
  to   = aws_iam_role_policy_attachment.irsa_inline["eso"]
}
