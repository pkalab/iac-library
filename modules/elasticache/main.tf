data "aws_caller_identity" "current" {}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.environment}-cache-subnets"
  subnet_ids = var.subnet_ids
}

# checkov skip=CKV_AWS_382: Open egress is intentional for outbound connectivity
resource "aws_security_group" "cache" {
  name        = "${var.environment}-cache-sg"
  description = "ElastiCache security group for ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
    description     = "Allow Redis/Memcached from allowed security groups"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
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

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token
  kms_key_id                 = aws_kms_key.elasticache[0].arn

  maintenance_window       = var.maintenance_window
  snapshot_retention_limit = var.snapshot_retention_limit

  tags = { Name = "${var.environment}-redis", Environment = var.environment }
}

resource "aws_kms_key" "elasticache" {
  count                   = var.engine == "redis" ? 1 : 0
  description             = "ElastiCache encryption key for ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "elasticache" {
  count  = var.engine == "redis" ? 1 : 0
  key_id = aws_kms_key.elasticache[0].key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowElastiCacheServiceUse"
        Effect    = "Allow"
        Principal = { Service = "elasticache.amazonaws.com" }
        Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "elasticache" {
  count         = var.engine == "redis" ? 1 : 0
  name          = "alias/${var.environment}-elasticache"
  target_key_id = aws_kms_key.elasticache[0].key_id
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
