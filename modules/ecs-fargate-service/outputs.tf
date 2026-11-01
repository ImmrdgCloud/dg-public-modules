output "alb_dns_name" {
  value = try(aws_lb.service[0].dns_name, null)
}

output "cluster_name" {
  value = aws_ecs_cluster.service.name
}

output "service_name" {
  value = aws_ecs_service.service.name
}

output "task_security_group_id" {
  value = aws_security_group.task.id
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.service.name
}

output "secret_parameter_arns" {
  value     = { for name, parameter in aws_ssm_parameter.secret : name => parameter.arn }
  sensitive = true
}
