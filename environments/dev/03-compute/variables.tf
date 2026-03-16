###############################################################################
# Layer 03-compute - Variables
###############################################################################

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "state_bucket" {
  description = "S3 bucket name for remote state"
  type        = string
}

# ---------- EKS ----------

variable "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  type        = string
}

variable "eks_endpoint_public_access" {
  description = "Enable public access to EKS API"
  type        = bool
}

variable "eks_enabled_log_types" {
  description = "EKS control plane log types"
  type        = list(string)
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
}

variable "eks_node_capacity_type" {
  description = "Node capacity type (ON_DEMAND or SPOT)"
  type        = string
}

variable "eks_node_disk_size" {
  description = "Node disk size in GB"
  type        = number
}

variable "eks_node_desired_size" {
  description = "Desired node count"
  type        = number
}

variable "eks_node_min_size" {
  description = "Minimum node count"
  type        = number
}

variable "eks_node_max_size" {
  description = "Maximum node count"
  type        = number
}

# ---------- Application ----------

variable "app_namespace" {
  description = "Kubernetes namespace for the app"
  type        = string
}

variable "app_service_account_name" {
  description = "Kubernetes service account name for IRSA"
  type        = string
}
