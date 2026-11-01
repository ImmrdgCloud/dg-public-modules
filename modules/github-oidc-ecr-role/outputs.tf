output "oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.github_actions.arn
}

output "role_arn" {
  value = module.github_actions_role.arn
}
