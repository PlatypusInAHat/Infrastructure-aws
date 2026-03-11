###############################################################################
# Layer 03-compute - Variables
###############################################################################

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "lab-aws"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "state_bucket" {
  default     = "lab-aws-terraform-state-361183471902"
  description = "S3 bucket name for remote state"
  type        = string
}

# ---------- EKS ----------

variable "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "eks_endpoint_public_access" {
  description = "Enable public access to EKS API"
  type        = bool
  default     = true
}

variable "eks_enabled_log_types" {
  description = "EKS control plane log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_capacity_type" {
  description = "Node capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_node_disk_size" {
  description = "Node disk size in GB"
  type        = number
  default     = 30
}

variable "eks_node_desired_size" {
  description = "Desired node count"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum node count"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum node count"
  type        = number
  default     = 5
}

# ---------- Application ----------

variable "app_namespace" {
  description = "Kubernetes namespace for the app"
  type        = string
  default     = "sample-app"
}

variable "app_service_account_name" {
  description = "Kubernetes service account name for IRSA"
  type        = string
  default     = "app-sa"
}
