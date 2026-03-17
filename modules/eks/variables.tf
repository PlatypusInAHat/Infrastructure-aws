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
}

variable "enabled_log_types" {
  description = "List of EKS control plane log types to enable"
  type        = list(string)
}

# ---------- Node Group Variables ----------

variable "node_groups" {
  description = "Map of node group configurations"
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

# ---------- Legacy Variables (Optional for IDE Compatibility) ----------

variable "node_instance_types" {
  type    = list(string)
  default = null
}

variable "node_capacity_type" {
  type    = string
  default = null
}

variable "node_disk_size" {
  type    = number
  default = null
}

variable "node_desired_size" {
  type    = number
  default = null
}

variable "node_min_size" {
  type    = number
  default = null
}

variable "node_max_size" {
  type    = number
  default = null
}

# ---------- IRSA Variables ----------

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
}

variable "app_service_account_name" {
  description = "Kubernetes service account name for the application"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}
