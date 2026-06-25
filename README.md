# Infrastructure as Code Library

A comprehensive Terraform module collection for AWS infrastructure.

## Modules

| Module | Description |
|--------|-------------|
| [networking](./modules/networking/) | VPC, subnets, NAT, flow logs, transit gateway |
| [eks](./modules/eks/) | EKS cluster, node groups, IRSA, addons |
| [rds](./modules/rds/) | RDS instances, replicas, parameter groups |
| [elasticache](./modules/elasticache/) | Redis and Memcached clusters |
| [vault](./modules/vault/) | Vault HA on EKS with DynamoDB + KMS unseal |
| [consul](./modules/consul/) | Consul server cluster on EKS |
| [compliance](./modules/compliance/) | AWS Config, GuardDuty, Security Hub, KMS |

## Quick Start

```hcl
module "networking" {
  source = "./modules/networking"
  environment = "dev"
  vpc_cidr   = "10.0.0.0/16"
}

module "eks" {
  source = "./modules/eks"
  environment = "dev"
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
}
```

## Prerequisites

- Terraform >= 1.7
- AWS credentials configured
- tflint, checkov, terraform-docs installed (for development)
