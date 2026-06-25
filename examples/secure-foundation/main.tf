module "networking" {
  source             = "../../modules/networking"
  environment        = "prod"
  vpc_cidr           = "10.2.0.0/16"
  enable_flow_logs   = true
  flow_log_retention = 365
}

module "compliance" {
  source                    = "../../modules/compliance"
  environment               = "prod"
  cis_standards_control_arn = "arn:aws:securityhub:us-east-1:${data.aws_caller_identity.current.account_id}:standards/cis-aws-foundations-benchmark/v/1.4.0"
}

data "aws_caller_identity" "current" {}
