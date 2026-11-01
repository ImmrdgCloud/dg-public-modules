output "alb_dns_name" {
  value = try(module.alb.dns_name, null)
}

output "cluster_name" {
  value = module.ecs.cluster_name
}

output "service_name" {
  value = module.ecs.services["service"].name
}

output "task_security_group_id" {
  value = module.task_security_group.security_group_id
}

output "log_group_name" {
  value = var.log_group_name
}

output "secret_parameter_arns" {
  value = {
    for name, parameter_name in var.secret_parameter_names :
    name => "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${parameter_name}"
  }
  sensitive = true
}
