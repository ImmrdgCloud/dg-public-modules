variable "name_prefix" { type = string }
variable "team_prefix" { type = string }
variable "resource_name" { type = string }
variable "service_name_suffix" {
  type    = string
  default = ""
}
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "cpu" { type = number }
variable "memory" { type = number }
variable "desired_count" { type = number }
variable "container_definition" {
  description = "Single ECS container definition. The wrapper supplies the stable upstream key and creation flag."
  type = object({
    name                     = string
    image                    = string
    essential                = optional(bool, true)
    command                  = optional(list(string), [])
    entrypoint               = optional(list(string), [])
    cpu                      = optional(number)
    memory                   = optional(number)
    memory_reservation       = optional(number)
    readonly_root_filesystem = optional(bool)
    working_directory        = optional(string)
    user                     = optional(string)
    port_mappings            = optional(list(any), [])
    environment              = optional(list(object({ name = string, value = string })), [])
    secrets                  = optional(list(object({ name = string, valueFrom = string })), [])
    log_configuration        = optional(any, {})
    health_check             = optional(any, {})
    linux_parameters         = optional(any, {})
    mount_points             = optional(list(any), [])
    volumes_from             = optional(list(any), [])
    depends_on               = optional(list(any), [])
    docker_labels            = optional(map(string), {})
    system_controls          = optional(list(any), [])
    ulimits                  = optional(list(any), [])
    repository_credentials   = optional(any, {})
    firelens_configuration   = optional(any, {})
  })
}
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
variable "ssm_parameter_arns" {
  type    = list(string)
  default = []
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
