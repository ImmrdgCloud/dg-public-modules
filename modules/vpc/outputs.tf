output "vpc_id" {
  description = "ID of the shared services VPC"
  value       = aws_vpc.shared_services.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets, ordered by Availability Zone"
  value = [
    for key in sort([
      for key, definition in local.subnet_definitions : key if definition.tier == "public"
    ]) : aws_subnet.this[key].id
  ]
}

output "subnet_ids_by_tier" {
  description = "Subnet IDs grouped by tier and ordered by subnet name"
  value = {
    for tier in keys(local.subnet_tiers) :
    tier => [
      for key in sort([
        for key, definition in local.subnet_definitions : key if definition.tier == tier
      ]) : aws_subnet.this[key].id
    ]
  }
}
