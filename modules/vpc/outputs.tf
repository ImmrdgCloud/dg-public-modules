output "vpc_id" {
  description = "ID of the shared services VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets, ordered by Availability Zone"
  value = [
    for subnet in module.vpc.public_subnets : subnet
  ]
}

output "subnet_ids_by_tier" {
  description = "Subnet IDs grouped by tier and ordered by subnet name"
  value = {
    public   = module.vpc.public_subnets
    app      = slice(module.vpc.private_subnets, 0, length(var.app_subnet_cidrs))
    database = slice(module.vpc.private_subnets, length(var.app_subnet_cidrs), length(var.app_subnet_cidrs) + length(var.db_subnet_cidrs))
    storage  = slice(module.vpc.private_subnets, length(var.app_subnet_cidrs) + length(var.db_subnet_cidrs), length(module.vpc.private_subnets))
  }
}
