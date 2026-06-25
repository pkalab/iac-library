data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

# checkov skip=CKV_AWS_18: This bucket IS the access log destination; logging to itself is circular
# checkov skip=CKV_AWS_145: Access logs don't require KMS; AES256 is sufficient
# checkov skip=CKV2_AWS_62: NLB writes directly via bucket policy; no event notification needed
resource "aws_s3_bucket" "this" {
  bucket        = "${var.name_prefix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "abort-incomplete-upload"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowELBLogging"
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.main.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      },
      {
        Sid       = "AllowELBLogDelivery"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.elb.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid       = "AllowELBLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.elb.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.this.arn
      },
    ]
  })
}
