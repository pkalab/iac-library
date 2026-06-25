variable "environment" {
  description = "Environment name"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for NLB"
  type        = list(string)
}

variable "namespace" {
  description = "Kubernetes namespace for Consul"
  type        = string
  default     = "consul"
}
