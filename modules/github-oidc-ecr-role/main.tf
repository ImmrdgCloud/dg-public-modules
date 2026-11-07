data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github_actions" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

locals {
  role_name         = "${var.name_prefix}-${var.team_prefix}-${var.resource_name}"
  oidc_provider_arn = var.create_oidc_provider ? module.github_actions_provider.arn : data.aws_iam_openid_connect_provider.github_actions[0].arn
  oidc_provider_url = var.create_oidc_provider ? module.github_actions_provider.url : data.aws_iam_openid_connect_provider.github_actions[0].url
}

module "github_actions_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "~> 5.0"

  create = var.create_oidc_provider
  tags   = var.tags
}

module "ecr_publish_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name = "${local.role_name}-publish-${var.ecr_repository}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository}"
      },
    ]
  })
}

module "github_actions_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"

  name         = local.role_name
  subjects     = ["repo:${var.github_owner}/${var.github_repository}:ref:refs/heads/main"]
  provider_url = trimsuffix(trimprefix(local.oidc_provider_url, "https://"), "/")
  policies     = { ecr_publish = module.ecr_publish_policy.arn }
  tags         = var.tags

  depends_on = [module.github_actions_provider]
}
