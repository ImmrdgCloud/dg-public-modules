variable "name_prefix" { type = string }
variable "team_prefix" { type = string }
variable "resource_name" { type = string }

variable "dockerfile_content" {
  description = "Raw Dockerfile text to build. Terraform base64-encodes this and injects it into the CodeBuild buildspec as an environment variable — no source repo or GitHub auth required."
  type        = string
}

variable "image_retention_count" {
  description = "Number of ECR images to retain per ECR lifecycle policy."
  type        = number
  default     = 10
}

variable "build_timeout_minutes" {
  description = "CodeBuild project build timeout in minutes."
  type        = number
  default     = 15
}

variable "compute_type" {
  description = "CodeBuild environment compute type."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "tags" {
  type    = map(string)
  default = {}
}
