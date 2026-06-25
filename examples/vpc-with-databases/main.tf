module "networking" {
  source           = "../../modules/networking"
  environment      = "staging"
  vpc_cidr         = "10.1.0.0/16"
  az_count         = 3
  enable_flow_logs = true
}

module "rds" {
  source      = "../../modules/rds"
  environment = "staging"
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.database_subnet_ids
  db_name     = "appdb"
  engine      = "postgres"
  password    = var.rds_password
}

module "elasticache" {
  source      = "../../modules/elasticache"
  environment = "staging"
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids
  engine      = "redis"
}
