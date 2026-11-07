variable "aws_region" { type = string }
variable "github_owner" { type = string }
variable "github_repository" { type = string }
variable "ecr_repository" { type = string }
variable "name_prefix" { type = string }
variable "team_prefix" { type = string }
variable "resource_name" { type = string }
variable "tags" { type = map(string) }
variable "create_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC provider. Set false only when it already exists."
  type        = bool
  default     = true
}
