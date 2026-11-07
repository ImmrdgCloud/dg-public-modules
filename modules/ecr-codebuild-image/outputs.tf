output "image_uri" {
  description = "Full ECR image URI pointing to the :latest tag — pass this to atlantis_image."
  value       = "${aws_ecr_repository.this.repository_url}:latest"
}

output "ecr_repository_url" {
  description = "Base ECR repository URL (without tag)."
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name."
  value       = aws_ecr_repository.this.name
}

output "codebuild_project_name" {
  description = "CodeBuild project name. Trigger a build with: aws codebuild start-build --project-name <value>"
  value       = aws_codebuild_project.this.name
}


