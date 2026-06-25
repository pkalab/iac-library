data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "this" {
  name                          = "${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = { Name = "${var.environment}-trail", Environment = var.environment }
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.environment}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      Condition = {
        StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
      }
    }]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "cloudtrail" {
  description             = "CloudTrail encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key" "compliance" {
  description             = "Compliance encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_config_configuration_recorder" "this" {
  name     = "${var.environment}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_delivery_channel" "this" {
  name           = "${var.environment}-config-delivery"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id
  sns_topic_arn  = aws_sns_topic.config.arn
}

resource "aws_sns_topic" "config" {
  name = "${var.environment}-config-notifications"
}

resource "aws_iam_role" "config" {
  name = "${var.environment}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "config" {
  name = "${var.environment}-config-policy"
  role = aws_iam_role.config.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:*",
        "sns:*",
        "config:*",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_guardduty_detector" "this" {
  enable = true
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
  }
}

resource "aws_guardduty_publishing_destination" "this" {
  detector_id     = aws_guardduty_detector.this.id
  destination_arn = aws_s3_bucket.cloudtrail.arn
  kms_key_arn     = aws_kms_key.compliance.arn
}

resource "aws_securityhub_account" "this" {
  enable_default_standards = false
}

resource "aws_securityhub_standards_control" "cis" {
  standards_control_arn = "arn:aws:securityhub:${var.region}:${data.aws_caller_identity.current.account_id}:standards/cis-aws-foundations-benchmark/v/1.4.0"
  control_status         = "ENABLED"
}

resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length      = 16
  require_lowercase_characters = true
  require_uppercase_characters = true
  require_numbers              = true
  require_symbols              = true
  max_password_age            = 90
  password_reuse_prevention   = 5
}
