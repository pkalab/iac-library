module "networking" {
  source            = "../../modules/networking"
  environment       = "prod"
  vpc_cidr          = "10.2.0.0/16"
  enable_flow_logs  = true
  flow_log_retention = 365
}

module "compliance" {
  source      = "../../modules/compliance"
  environment = "prod"
  region      = "us-east-1"
}
