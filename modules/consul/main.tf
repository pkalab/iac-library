data "aws_caller_identity" "current" {}
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

resource "aws_kms_key" "consul" {
  description             = "Consul gossip encryption key for ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_ciphertext" "consul_gossip" {
  key_id    = aws_kms_key.consul.key_id
  plaintext = var.gossip_secret != "" ? var.gossip_secret : "0123456789abcdef0123456789abcdef"
}

resource "aws_iam_policy" "consul" {
  name = "${var.environment}-consul-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:Decrypt",
        "kms:GenerateRandom",
      ]
      Resource = aws_kms_key.consul.arn
    }]
  })
}

resource "aws_iam_role" "consul" {
  name = "${var.environment}-consul-irsa"
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
          "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:consul-server"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "consul" {
  role       = aws_iam_role.consul.name
  policy_arn = aws_iam_policy.consul.arn
}

resource "aws_lb" "consul" {
  name               = "${var.environment}-consul-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids
  tags = { Name = "${var.environment}-consul-nlb", Environment = var.environment }
}

resource "aws_lb_listener" "consul" {
  load_balancer_arn = aws_lb.consul.arn
  port              = 8501
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.consul.arn
  }
}

resource "aws_lb_target_group" "consul" {
  name        = "${var.environment}-consul-tg"
  port        = 8501
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled  = true
    port     = 8501
    protocol = "HTTPS"
    path     = "/v1/status/leader"
  }
}
