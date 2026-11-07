locals {
  name = "${var.name_prefix}-${var.team_prefix}-${var.resource_name}"
}

module "task_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name         = "${local.name}-${var.task_security_group_prefix}-sg"
  description  = var.task_security_group_description
  vpc_id       = var.vpc_id
  egress_rules = ["all-all"]
  ingress_with_source_security_group_id = var.load_balancer == null ? [] : [{
    from_port                = var.load_balancer.container_port
    to_port                  = var.load_balancer.container_port
    protocol                 = "tcp"
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

module "cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.0"

  cluster_name = local.name
  cluster_settings = [{
    name  = "containerInsights"
    value = "disabled"
  }]
  tags = var.tags
}

module "service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.0"

  name          = "${local.name}${var.service_name_suffix}"
  cluster_arn   = module.cluster.arn
  cpu           = var.cpu
  memory        = var.memory
  desired_count = var.desired_count

  container_definitions = {
    main = {
      create                   = true
      name                     = var.container_definition.name
      image                    = var.container_definition.image
      essential                = var.container_definition.essential
      command                  = var.container_definition.command
      entrypoint               = var.container_definition.entrypoint
      cpu                      = var.container_definition.cpu
      memory                   = var.container_definition.memory
      memory_reservation       = var.container_definition.memory_reservation
      readonly_root_filesystem = var.container_definition.readonly_root_filesystem
      working_directory        = var.container_definition.working_directory
      user                     = var.container_definition.user
      port_mappings            = var.container_definition.port_mappings
      environment              = var.container_definition.environment
      secrets                  = var.container_definition.secrets
      log_configuration        = var.container_definition.log_configuration
      health_check             = var.container_definition.health_check
      linux_parameters         = var.container_definition.linux_parameters
      mount_points             = var.container_definition.mount_points
      volumes_from             = var.container_definition.volumes_from
      depends_on               = var.container_definition.depends_on
      docker_labels            = var.container_definition.docker_labels
      system_controls          = var.container_definition.system_controls
      ulimits                  = var.container_definition.ulimits
      repository_credentials   = var.container_definition.repository_credentials
      firelens_configuration   = var.container_definition.firelens_configuration
    }
  }
  assign_public_ip                   = true
  subnet_ids                         = var.public_subnet_ids
  security_group_ids                 = [module.task_security_group.security_group_id]
  create_security_group              = false
  create_task_exec_iam_role          = true
  task_exec_iam_role_name            = "${local.name}-execution"
  task_exec_iam_role_use_name_prefix = false
  task_exec_ssm_param_arns           = var.ssm_parameter_arns
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
  tags = var.tags
}
