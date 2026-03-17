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

variable "eks_node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    disk_size      = number
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = optional(map(string), {})
  }))
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
