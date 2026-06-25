output "dynamodb_table_name" {
  description = "DynamoDB table for Vault storage"
  value       = aws_dynamodb_table.vault.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.vault.arn
}

output "kms_key_id" {
  description = "KMS key ID for auto-unseal"
  value       = aws_kms_key.vault_unseal.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for auto-unseal"
  value       = aws_kms_key.vault_unseal.arn
}

output "irsa_role_arn" {
  description = "IRSA role ARN for Vault"
  value       = aws_iam_role.vault.arn
}

output "nlb_dns_name" {
  description = "NLB DNS name for Vault"
  value       = aws_lb.vault.dns_name
}

output "nlb_zone_id" {
  description = "NLB zone ID"
  value       = aws_lb.vault.zone_id
}
