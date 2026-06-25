data "aws_caller_identity" "current" {}
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

module "nlb_logs" {
  source      = "../s3-access-logs"
  name_prefix = "${var.environment}-vault-nlb-logs"
}

resource "aws_dynamodb_table" "vault" {
  name         = "${var.environment}-vault-storage"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "key"

  attribute {
    name = "key"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.vault_unseal.arn
  }

  tags = { Name = "${var.environment}-vault-storage", Environment = var.environment }
}

resource "aws_kms_key" "vault_unseal" {
  description             = "Vault auto-unseal key for ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = { Name = "${var.environment}-vault-unseal", Environment = var.environment }
}

resource "aws_kms_key_policy" "vault_unseal" {
  key_id = aws_kms_key.vault_unseal.key_id
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
        Sid       = "AllowVaultUnseal"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.vault.arn }
        Action    = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey"]
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/${var.environment}-vault-unseal"
  target_key_id = aws_kms_key.vault_unseal.key_id
}

resource "aws_iam_policy" "vault" {
  name = "${var.environment}-vault-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
        ]
        Resource = aws_dynamodb_table.vault.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey",
        ]
        Resource = aws_kms_key.vault_unseal.arn
      },
    ]
  })
}

resource "aws_iam_role" "vault" {
  name = "${var.environment}-vault-irsa"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:vault"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vault" {
  role       = aws_iam_role.vault.name
  policy_arn = aws_iam_policy.vault.arn
}

resource "aws_lb" "vault" {
  name                             = "${var.environment}-vault-nlb"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = var.subnet_ids
  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = module.nlb_logs.bucket_id
    prefix  = "vault-nlb"
    enabled = true
  }

  tags = { Name = "${var.environment}-vault-nlb", Environment = var.environment }
}

resource "aws_lb_listener" "vault" {
  load_balancer_arn = aws_lb.vault.arn
  port              = 8200
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}

resource "aws_lb_target_group" "vault" {
  name        = "${var.environment}-vault-tg"
  port        = 8200
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled  = true
    port     = 8200
    protocol = "HTTP"
    path     = "/v1/sys/health?standbyok=true"
  }
}
