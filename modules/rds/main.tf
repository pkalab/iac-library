data "aws_caller_identity" "current" {}

resource "aws_db_subnet_group" "this" {
  name        = "${var.environment}-rds-subnets"
  subnet_ids  = var.subnet_ids
  description = "Subnet group for ${var.environment} RDS instances"
  tags        = { Name = "${var.environment}-rds-sg", Environment = var.environment }
}

resource "aws_db_parameter_group" "this" {
  count       = var.create_parameter_group ? 1 : 0
  name        = "${var.environment}-rds-params"
  family      = var.parameter_group_family
  description = "Custom parameter group for ${var.environment}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "0"
  }

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
}

# checkov skip=CKV_AWS_382: Open egress is intentional for outbound connectivity
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "RDS security group for ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.engine_port
    to_port         = var.engine_port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
    description     = "Allowed security groups"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = { Name = "${var.environment}-rds-sg", Environment = var.environment }
}

resource "aws_db_instance" "this" {
  identifier = "${var.environment}-${var.db_name}"

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = var.engine_port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = var.create_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  multi_az                   = true
  auto_minor_version_upgrade = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  copy_tags_to_snapshot      = true

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn

  enabled_cloudwatch_logs_exports = var.cloudwatch_logs_exports

  tags = {
    Name        = "${var.environment}-${var.db_name}"
    Environment = var.environment
  }
}

resource "aws_kms_key" "rds" {
  description             = "RDS encryption key for ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "rds" {
  key_id = aws_kms_key.rds.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.environment}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
