locals {
  name = "${var.name_prefix}-${var.team_prefix}-${var.api_name}"
}

resource "aws_apigatewayv2_api" "this" {
  name          = local.name
  protocol_type = "HTTP"
  description   = var.description
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "this" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = var.integration_type
  integration_uri        = var.integration_uri
  integration_method     = var.integration_method
  payload_format_version = contains(["AWS_PROXY", "HTTP_PROXY"], var.integration_type) ? var.payload_format_version : null
}

resource "aws_apigatewayv2_route" "this" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = var.route_key
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
  tags        = var.tags
}
