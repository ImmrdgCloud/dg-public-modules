variable "aws_region" { type = string }
variable "github_owner" { type = string }
variable "github_repository" { type = string }
variable "ecr_repository" { type = string }
variable "name_prefix" { type = string }
variable "team_prefix" { type = string }
variable "role_name" { type = string }
variable "tags" { type = map(string) }
