output "cloudtrail_name" {
  description = "CloudTrail name"
  value       = aws_cloudtrail.this.id
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = aws_cloudtrail.this.arn
}

output "cloudtrail_bucket" {
  description = "CloudTrail S3 bucket name"
  value       = aws_s3_bucket.cloudtrail.id
}

output "config_recorder_name" {
  description = "AWS Config recorder name"
  value       = aws_config_configuration_recorder.this.name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.this.id
}

output "securityhub_account_id" {
  description = "Security Hub account ID"
  value       = aws_securityhub_account.this.id
}

output "kms_key_arns" {
  description = "KMS key ARNs"
  value = {
    cloudtrail = aws_kms_key.cloudtrail.arn
    compliance = aws_kms_key.compliance.arn
  }
}
