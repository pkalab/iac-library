module "networking" {
  source      = "../../modules/networking"
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
}

module "eks" {
  source      = "../../modules/eks"
  environment = "dev"
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids
}
