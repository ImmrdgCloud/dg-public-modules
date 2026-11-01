locals {
  name = "${var.name_prefix}-${var.team_prefix}-${var.resource_name}"
}

module "http_api" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.0"

  name          = local.name
  description   = var.description
  protocol_type = "HTTP"
  tags          = var.tags

  routes = {
    default = {
      route_key = var.route_key
      integration = {
        uri                    = var.integration_uri
        type                   = var.integration_type
        method                 = var.integration_method
        payload_format_version = var.payload_format_version
      }
    }
  }

  stage_name = var.stage_name
}
