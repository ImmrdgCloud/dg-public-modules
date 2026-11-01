variable "name_prefix" { type = string }
variable "team_prefix" { type = string }
variable "service_name" { type = string }
variable "service_name_suffix" {
  type    = string
  default = ""
}
variable "service_name" { type = string }
variable "task_family" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "cpu" { type = number }
variable "memory" { type = number }
variable "desired_count" { type = number }
variable "container_definitions" { type = string }
variable "log_group_name" { type = string }
variable "log_retention_days" { type = number }
variable "execution_ssm_policy_name" { type = string }
variable "task_security_group_description" { type = string }
variable "task_security_group_prefix" { type = string }
variable "task_egress_description" {
  type    = string
  default = null
}
variable "tags" { type = map(string) }
variable "task_managed_policy_arns" {
  type    = list(string)
  default = []
}
variable "secret_parameters" {
  type = map(object({
    name  = string
    value = string
  }))
  default   = {}
  sensitive = true
}
variable "load_balancer" {
  type = object({
    name                       = string
    target_group_name          = string
    container_name             = string
    container_port             = number
    health_check_path          = string
    security_group_description = string
    task_ingress_description   = string
  })
  default = null
}
