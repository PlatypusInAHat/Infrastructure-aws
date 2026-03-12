variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets for the node group"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of public subnets for the EKS cluster"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  type        = string
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS API endpoint"
  type        = bool
  default     = true
}

variable "enabled_log_types" {
  description = "List of EKS control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

# ---------- Node Group Variables ----------

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["c7i-flex.large"]
}

variable "node_capacity_type" {
  description = "Capacity type for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Disk size for worker nodes (GB)"
  type        = number
  default     = 30
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

# ---------- IRSA Variables ----------

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "default"
}

variable "app_service_account_name" {
  description = "Kubernetes service account name for the application"
  type        = string
  default     = "app-sa"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
