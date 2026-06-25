variable "environment" {
  description = "Environment name"
  type        = string
}

variable "force_destroy" {
  description = "Force destroy S3 buckets"
  type        = bool
  default     = false
}

variable "cis_standards_control_arn" {
  description = "ARN of the CIS AWS Foundations Benchmark standards control to enable"
  type        = string
}
