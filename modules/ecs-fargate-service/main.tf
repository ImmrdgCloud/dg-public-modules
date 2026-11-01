locals {
  name = "${var.name_prefix}-${var.team_prefix}-${var.resource_name}"
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

module "task_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name         = "${local.name}-${var.task_security_group_prefix}-sg"
  description  = var.task_security_group_description
  vpc_id       = var.vpc_id
  egress_rules = ["all-all"]
  ingress_with_source_security_group_id = var.load_balancer == null ? [] : [{
    rule                     = "tcp-${var.load_balancer.container_port}"
    source_security_group_id = module.alb_security_group.security_group_id
    description              = var.load_balancer.task_ingress_description
  }]
  tags = var.tags
}

module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"
  create  = var.load_balancer != null

  name                = "${local.name}-alb-sg"
  description         = try(var.load_balancer.security_group_description, null)
  vpc_id              = var.vpc_id
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  tags                = var.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"
  create  = var.load_balancer != null

  name               = try(var.load_balancer.name, null)
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.public_subnet_ids
  security_groups    = [module.alb_security_group.security_group_id]
  target_groups = {
    service = {
      name_prefix       = substr(try(var.load_balancer.target_group_name, "service"), 0, 6)
      protocol          = "HTTP"
      port              = try(var.load_balancer.container_port, 80)
      target_type       = "ip"
      create_attachment = false
      health_check = {
        path = try(var.load_balancer.health_check_path, "/")
      }
    }
  }
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward  = { target_group_key = "service" }
    }
  }
  tags = var.tags
}

module "parameters" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "~> 1.0"

  for_each = var.secret_parameter_names
  name     = each.value
  value    = var.secret_parameter_values[each.key]
  type     = "SecureString"
  tags     = var.tags
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = local.name
  cluster_settings = [{
    name  = "containerInsights"
    value = "disabled"
  }]

  services = {
    service = {
      name                               = "${local.name}${var.service_name_suffix}"
      cpu                                = var.cpu
      memory                             = var.memory
      desired_count                      = var.desired_count
      container_definitions              = jsondecode(var.container_definitions)
      assign_public_ip                   = true
      subnet_ids                         = var.public_subnet_ids
      security_group_ids                 = [module.task_security_group.security_group_id]
      create_security_group              = false
      create_task_exec_iam_role          = true
      task_exec_iam_role_name            = "${local.name}-execution"
      task_exec_iam_role_use_name_prefix = false
      task_exec_ssm_param_arns           = [for parameter in module.parameters : parameter.ssm_parameter_arn]
      create_tasks_iam_role              = true
      tasks_iam_role_name                = "${local.name}-task"
      tasks_iam_role_use_name_prefix     = false
      tasks_iam_role_policies            = { for arn in var.task_managed_policy_arns : arn => arn }
      load_balancer = var.load_balancer == null ? {} : {
        service = {
          target_group_arn = module.alb.target_groups["service"].arn
          container_name   = var.load_balancer.container_name
          container_port   = var.load_balancer.container_port
        }
      }
    }
  }
  tags = var.tags
}
