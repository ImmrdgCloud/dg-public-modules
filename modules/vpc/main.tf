locals {
  full_name = "${var.name_prefix}-${var.team_prefix}-${var.resource_name}"
  private_subnets = concat(
    var.app_subnet_cidrs,
    var.db_subnet_cidrs,
    var.storage_subnet_cidrs,
  )
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.full_name
  cidr = var.vpc_cidr
  azs  = var.availability_zones

  public_subnets  = var.public_subnet_cidrs
  private_subnets = local.private_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = false

  tags = {
    ManagedBy = "terraform"
    Project   = var.resource_name
  }
}

moved {
  from = aws_vpc.shared_services
  to   = module.vpc.aws_vpc.this[0]
}

moved {
  from = aws_internet_gateway.shared_services
  to   = module.vpc.aws_internet_gateway.this[0]
}
