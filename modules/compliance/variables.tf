variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "force_destroy" {
  description = "Force destroy S3 buckets"
  type        = bool
  default     = false
}
