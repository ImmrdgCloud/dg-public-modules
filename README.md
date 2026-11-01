# DG Public Terraform Modules

Provider-agnostic Terraform module packages for AWS infrastructure. Every module:

- has no provider configuration;
- declares its provider requirements and Terraform version;
- accepts names, tags, and infrastructure identifiers from the consumer; and
- is versioned from this repository's `main` branch.

Each module requires `name_prefix`, `team_prefix`, and a resource-specific
name input. It composes resource names as
`${name_prefix}-${team_prefix}-${resource_name}`.

Available modules:

- `vpc`: VPC, subnet tiers, route tables, and an S3 gateway endpoint
- `ecs-fargate-service`: Fargate service with optional public ALB, logs, IAM, SSM secrets, and security groups
- `api-gateway`: HTTP API, one configurable integration, route, and stage
- `github-oidc-ecr-role`: GitHub Actions OIDC role for publishing to a caller-selected ECR repository
