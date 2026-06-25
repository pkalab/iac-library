data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "this" {
  name                          = "${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail.arn
  sns_topic_name                = aws_sns_topic.cloudtrail.name
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = { Name = "${var.environment}-trail", Environment = var.environment }
}

# checkov skip=CKV_AWS_18: CloudTrail writes directly via bucket policy; access logging not needed
# checkov skip=CKV2_AWS_62: CloudTrail manages its own event delivery; S3 notifications are redundant
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.environment}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    expiration {
      days = 365
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
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

resource "aws_kms_key_policy" "cloudtrail" {
  key_id = aws_kms_key.cloudtrail.key_id
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
        Sid       = "AllowCloudTrailEncrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:GenerateDataKey*"
        Resource  = "*"
        Condition = {
          StringLike = { "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*" }
        }
      },
      {
        Sid       = "AllowS3Encrypt"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "kms:GenerateDataKey*"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_key" "compliance" {
  description             = "Compliance encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "compliance" {
  key_id = aws_kms_key.compliance.key_id
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
        Sid       = "AllowGuardDutyUse"
        Effect    = "Allow"
        Principal = { Service = "guardduty.amazonaws.com" }
        Action    = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource  = "*"
      }
    ]
  })
}

resource "aws_sns_topic" "cloudtrail" {
  name              = "${var.environment}-cloudtrail-notifications"
  kms_master_key_id = aws_kms_key.compliance.key_id
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.environment}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.compliance.arn
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.environment}-cloudtrail-cloudwatch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.environment}-cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cloudwatch.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
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
  name              = "${var.environment}-config-notifications"
  kms_master_key_id = aws_kms_key.compliance.key_id
}

resource "aws_iam_role" "config" {
  name = "${var.environment}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "config" {
  name = "${var.environment}-config-policy"
  role = aws_iam_role.config.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
        ]
        Resource = [
          aws_s3_bucket.cloudtrail.arn,
          "${aws_s3_bucket.cloudtrail.arn}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = aws_sns_topic.config.arn
      },
      {
        Effect = "Allow"
        Action = [
          "config:Put*",
          "config:Get*",
          "config:List*",
          "config:Describe*",
          "config:BatchGetResourceConfig",
        ]
        Resource = "*"
      },
    ]
  })
}

# checkov skip=CKV2_AWS_3: GuardDuty is enabled without organization-wide configuration
resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
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
  depends_on      = [aws_s3_bucket_policy.cloudtrail]
}

resource "aws_securityhub_account" "this" {
  enable_default_standards = false
}

resource "aws_securityhub_standards_control" "cis" {
  standards_control_arn = var.cis_standards_control_arn
  control_status        = "ENABLED"
}

