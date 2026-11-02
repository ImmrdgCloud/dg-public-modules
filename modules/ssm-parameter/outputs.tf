output "arn" {
  value = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name_prefix}/${var.team_prefix}/${var.parameter_name}"
}

output "name" {
  value = module.parameter.ssm_parameter_name
}
