output "kms_key_id" {
  description = "KMS key ID for gossip encryption"
  value       = aws_kms_key.consul.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.consul.arn
}

output "irsa_role_arn" {
  description = "IRSA role ARN for Consul"
  value       = aws_iam_role.consul.arn
}

output "nlb_dns_name" {
  description = "NLB DNS name for Consul"
  value       = aws_lb.consul.dns_name
}

output "nlb_zone_id" {
  description = "NLB zone ID"
  value       = aws_lb.consul.zone_id
}
