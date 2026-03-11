###############################################################################
# GitHub Actions OIDC Identity Provider & IAM Role
# Enables GitHub Actions to assume an IAM role via OIDC (no long-lived keys)
#
# Import commands (resources were initially created manually in AWS Console):
#   terraform import aws_iam_openid_connect_provider.github_actions \
#     arn:aws:iam::361183471902:oidc-provider/token.actions.githubusercontent.com
#   terraform import aws_iam_role.github_actions \
#     lab-aws-dev-github-actions-role
#   terraform import aws_iam_role_policy_attachment.github_actions_admin \
#     "lab-aws-dev-github-actions-role/arn:aws:iam::aws:policy/AdministratorAccess"
###############################################################################

# ---------- GitHub OIDC Identity Provider ----------

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprints (stable, no rotation needed)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(local.common_tags, {
    Name = "github-actions-oidc-provider"
  })
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
          Federated = aws_iam_openid_connect_provider.github_actions.arn
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
