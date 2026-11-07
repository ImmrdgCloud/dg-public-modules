data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name = "${var.name_prefix}-${var.team_prefix}-${var.resource_name}"

  # Buildspec is JSON (CodeBuild accepts both YAML and JSON).
  # The Dockerfile content is stored base64-encoded in the DOCKERFILE_B64
  # environment variable so that special characters, multi-line heredocs,
  # and quotes are never an issue in the buildspec string itself.
  buildspec = jsonencode({
    version = "0.2"
    phases = {
      pre_build = {
        commands = [
          "echo Logging in to Amazon ECR...",
          "aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI",
          "BUILD_TAG=$(echo $CODEBUILD_BUILD_ID | awk -F: '{print substr($2,1,8)}')",
        ]
      }
      build = {
        commands = [
          "echo Decoding inline Dockerfile...",
          "echo \"$DOCKERFILE_B64\" | base64 -d > Dockerfile",
          "echo Building Docker image...",
          "docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$BUILD_TAG .",
        ]
      }
      post_build = {
        commands = [
          "echo Pushing image to ECR...",
          "docker push $ECR_REPO_URI:latest",
          "docker push $ECR_REPO_URI:$BUILD_TAG",
          "echo Build complete on $(date).",
        ]
      }
    }
  })
}

# ── ECR Repository ────────────────────────────────────────────────────────────

resource "aws_ecr_repository" "this" {
  name                 = var.resource_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.image_retention_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_retention_count
      }
      action = { type = "expire" }
    }]
  })
}

# ── IAM Role for CodeBuild ────────────────────────────────────────────────────

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${local.name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.name}",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.name}:*",
    ]
  }

  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [aws_ecr_repository.this.arn]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${local.name}-codebuild-policy"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

# ── CodeBuild Project ─────────────────────────────────────────────────────────

resource "aws_codebuild_project" "this" {
  name          = local.name
  description   = "Build and push ${var.resource_name} Docker image to ECR (NO_SOURCE — Dockerfile is inline)"
  build_timeout = var.build_timeout_minutes
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = var.compute_type
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true # required for Docker daemon

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "ECR_REPO_URI"
      value = aws_ecr_repository.this.repository_url
    }

    # Dockerfile content stored as base64 to avoid quoting / heredoc issues
    # in the buildspec. The build phase decodes it back to a plain Dockerfile.
    environment_variable {
      name  = "DOCKERFILE_B64"
      value = base64encode(var.dockerfile_content)
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = local.buildspec
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${local.name}"
      status     = "ENABLED"
    }
  }

  tags = var.tags
}
