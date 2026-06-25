variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for DB subnet group"
  type        = list(string)
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "engine" {
  description = "Database engine (mysql, postgres, aurora, etc.)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version"
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "engine_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling"
  type        = number
  default     = 500
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "gp3"
}

variable "create_parameter_group" {
  description = "Create a custom parameter group"
  type        = bool
  default     = false
}

variable "parameter_group_family" {
  description = "Parameter group family"
  type        = string
  default     = "postgres16"
}

variable "parameter_group_name" {
  description = "Existing parameter group name"
  type        = string
  default     = ""
}

variable "parameters" {
  description = "List of parameters for custom parameter group"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "allowed_security_groups" {
  description = "Security group IDs allowed to connect"
  type        = list(string)
  default     = []
}

variable "backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 30
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention in days"
  type        = number
  default     = 7
}

variable "cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}
