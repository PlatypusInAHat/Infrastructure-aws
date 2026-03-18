###############################################################################
# GitHub Actions OIDC Identity Provider & IAM Role
# Enables GitHub Actions to assume an IAM role via OIDC (no long-lived keys)
#
# ---------- Config-Driven Imports ----------
# These resources were initially created manually in AWS Console to bootstrap CI/CD
# Terraform will automatically import them into its state using these blocks.



import {
  to = aws_iam_role.github_actions
  id = "lab-aws-dev-github-actions-role"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_admin
  id = "lab-aws-dev-github-actions-role/arn:aws:iam::aws:policy/AdministratorAccess"
}

# ---------- GitHub OIDC Identity Provider ----------

data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

# ---------- IAM Role for GitHub Actions ----------

resource "aws_iam_role" "github_actions" {
  name        = "${var.project_name}-${var.environment}-github-actions-role"
  description = "Role assumed by GitHub Actions via OIDC for Terraform deployments"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restrict to all repos under the PlatypusInAHat org
            "token.actions.githubusercontent.com:sub" = "repo:PlatypusInAHat/*:*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-github-actions-role"
  })
}

# ---------- Attach AdministratorAccess (matches role created in Console) ----------
# NOTE: For production, replace with a least-privilege custom policy.

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
