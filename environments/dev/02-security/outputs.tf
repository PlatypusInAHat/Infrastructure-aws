###############################################################################
# Layer 02-security - Outputs
# These outputs are consumed by layers 03-compute and 04-data
###############################################################################

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.security.alb_security_group_id
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.security.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "EKS nodes security group ID"
  value       = module.security.eks_nodes_security_group_id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.security.rds_security_group_id
}

# ---------- GitHub Actions OIDC ----------

output "github_actions_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions (set as secret AWS_ROLE_ARN)"
  value       = aws_iam_role.github_actions.arn
}
