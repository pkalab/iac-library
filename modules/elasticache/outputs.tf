output "replication_group_id" {
  description = "Redis replication group ID"
  value       = var.engine == "redis" ? aws_elasticache_replication_group.redis[0].id : null
}

output "replication_group_arn" {
  description = "Redis replication group ARN"
  value       = var.engine == "redis" ? aws_elasticache_replication_group.redis[0].arn : null
}

output "replication_group_endpoint" {
  description = "Redis primary endpoint"
  value       = var.engine == "redis" ? aws_elasticache_replication_group.redis[0].primary_endpoint_address : null
}

output "replication_group_reader_endpoint" {
  description = "Redis reader endpoint"
  value       = var.engine == "redis" ? aws_elasticache_replication_group.redis[0].reader_endpoint_address : null
}

output "memcached_cluster_id" {
  description = "Memcached cluster ID"
  value       = var.engine == "memcached" ? aws_elasticache_cluster.memcached[0].id : null
}

output "memcached_endpoint" {
  description = "Memcached configuration endpoint"
  value       = var.engine == "memcached" ? aws_elasticache_cluster.memcached[0].configuration_endpoint : null
}

output "cache_security_group_id" {
  description = "Cache security group ID"
  value       = aws_security_group.cache.id
}

output "cache_subnet_group_name" {
  description = "Cache subnet group name"
  value       = aws_elasticache_subnet_group.this.name
}
