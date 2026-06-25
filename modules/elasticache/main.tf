resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.environment}-cache-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "cache" {
  name        = "${var.environment}-cache-sg"
  description = "ElastiCache security group for ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-cache-sg", Environment = var.environment }
}

resource "aws_elasticache_replication_group" "redis" {
  count = var.engine == "redis" ? 1 : 0

  replication_group_id = "${var.environment}-redis"
  description          = "Redis cluster for ${var.environment}"
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  port                 = var.port

  parameter_group_name = aws_elasticache_parameter_group.redis[0].name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.cache.id]

  engine         = "redis"
  engine_version = var.engine_version

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  auth_token                  = var.auth_token

  maintenance_window       = var.maintenance_window
  snapshot_retention_limit = var.snapshot_retention_limit

  tags = { Name = "${var.environment}-redis", Environment = var.environment }
}

resource "aws_elasticache_parameter_group" "redis" {
  count  = var.engine == "redis" ? 1 : 0
  name   = "${var.environment}-redis-params"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = var.maxmemory_policy
  }
}

resource "aws_elasticache_cluster" "memcached" {
  count = var.engine == "memcached" ? 1 : 0

  cluster_id           = "${var.environment}-memcached"
  engine               = "memcached"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  port                 = var.port
  parameter_group_name = aws_elasticache_parameter_group.memcached[0].name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.cache.id]

  tags = { Name = "${var.environment}-memcached", Environment = var.environment }
}

resource "aws_elasticache_parameter_group" "memcached" {
  count  = var.engine == "memcached" ? 1 : 0
  name   = "${var.environment}-memcached-params"
  family = "memcached1.6"
}
