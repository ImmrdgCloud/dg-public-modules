module "parameter" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "~> 1.0"

  name  = "/${var.name_prefix}/${var.team_prefix}/${var.parameter_name}"
  value = var.value
  type  = "SecureString"
  tags  = var.tags
}
