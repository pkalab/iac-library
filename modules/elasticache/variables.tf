variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for cache subnet group"
  type        = list(string)
}

variable "engine" {
  description = "Cache engine (redis or memcached)"
  type        = string
  default     = "redis"
}

variable "engine_version" {
  description = "Engine version"
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "Cache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "port" {
  description = "Cache port"
  type        = number
  default     = 6379
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (Redis)"
  type        = number
  default     = 2
}

variable "num_cache_nodes" {
  description = "Number of cache nodes (Memcached)"
  type        = number
  default     = 2
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (Redis)"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = true
}

variable "maxmemory_policy" {
  description = "Redis maxmemory policy"
  type        = string
  default     = "allkeys-lru"
}

variable "auth_token" {
  description = "Redis auth token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_security_groups" {
  description = "Security group IDs allowed to connect"
  type        = list(string)
  default     = []
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "snapshot_retention_limit" {
  description = "Snapshot retention limit in days"
  type        = number
  default     = 7
}
