output "oidc_provider_arn" {
  value = local.oidc_provider_arn
}

output "role_arn" {
  value = module.github_actions_role.arn
}
