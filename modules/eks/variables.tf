variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "endpoint_private_access" {
  description = "Enable private endpoint access"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public endpoint access"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs with public access"
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "EC2 instance types for node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 50
}

variable "node_desired_size" {
  description = "Desired node count"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum node count"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum node count"
  type        = number
  default     = 10
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler IAM policy"
  type        = bool
  default     = true
}
