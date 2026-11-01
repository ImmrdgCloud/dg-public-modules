locals {
  name                     = "${var.name_prefix}-${var.team_prefix}-${var.service_name}"
  task_security_group_name = "${local.name}-sg"
}

resource "aws_security_group" "alb" {
  count = var.load_balancer == null ? 0 : 1

  name_prefix = "${local.name}-alb-"
  description = var.load_balancer.security_group_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-alb-sg" })
}

resource "aws_security_group" "task" {
  name_prefix = "${local.name}-${var.task_security_group_prefix}-"
  description = var.task_security_group_description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.load_balancer == null ? [] : [var.load_balancer]
    content {
      from_port       = ingress.value.container_port
      to_port         = ingress.value.container_port
      protocol        = "tcp"
      security_groups = [aws_security_group.alb[0].id]
      description     = ingress.value.task_ingress_description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = var.task_egress_description
  }

  tags = merge(var.tags, { Name = local.task_security_group_name })
}

resource "aws_lb" "service" {
  count = var.load_balancer == null ? 0 : 1

  name               = var.load_balancer.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.public_subnet_ids

  tags = var.tags
}

resource "aws_lb_target_group" "service" {
  count = var.load_balancer == null ? 0 : 1

  name        = var.load_balancer.target_group_name
  port        = var.load_balancer.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.load_balancer.health_check_path
    port                = tostring(var.load_balancer.container_port)
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  count = var.load_balancer == null ? 0 : 1

  load_balancer_arn = aws_lb.service[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[0].arn
  }
}

resource "aws_cloudwatch_log_group" "service" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_ssm_parameter" "secret" {
  for_each = var.secret_parameter_names

  name  = each.value
  type  = "SecureString"
  value = var.secret_parameter_values[each.key]
  tags  = var.tags
}

resource "aws_iam_role" "execution" {
  name               = "${local.name}-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_ssm" {
  name = "${local.name}-${var.execution_ssm_policy_name}"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters"]
      Resource = [for parameter in aws_ssm_parameter.secret : parameter.arn]
    }]
  })
}

resource "aws_iam_role" "task" {
  name               = "${local.name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "task_managed" {
  for_each = toset(var.task_managed_policy_arns)

  role       = aws_iam_role.task.name
  policy_arn = each.value
}

resource "aws_ecs_cluster" "service" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = var.tags
}

resource "aws_ecs_task_definition" "service" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions    = var.container_definitions
  tags                     = var.tags
}

resource "aws_ecs_service" "service" {
  name            = "${local.name}${var.service_name_suffix}"
  cluster         = aws_ecs_cluster.service.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = true
  }

  dynamic "load_balancer" {
    for_each = var.load_balancer == null ? [] : [var.load_balancer]
    content {
      target_group_arn = aws_lb_target_group.service[0].arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  tags = var.tags
}
