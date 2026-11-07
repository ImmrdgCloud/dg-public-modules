output "alb_dns_name" {
  value = try(module.alb.dns_name, null)
}

output "cluster_name" {
  value = module.cluster.name
}

output "service_name" {
  value = module.service.name
}

output "task_security_group_id" {
  value = module.task_security_group.security_group_id
}

output "log_group_name" {
  value = module.service.container_definitions["main"].cloudwatch_log_group_name
}
