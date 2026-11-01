output "oidc_provider_arn" {
  value = module.github_actions_provider.arn
}

output "role_arn" {
  value = module.github_actions_role.arn
}
