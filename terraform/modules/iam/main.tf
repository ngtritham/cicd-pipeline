# TODO: Create IAM roles and OIDC provider
#
# Phase 2 implementation will include:
#
# 1. ECS Task Execution Role
# - resource "aws_iam_role" "task_execution_role"
# - Permissions: Pull from ECR, write to CloudWatch Logs
# - Trust: ecs-tasks.amazonaws.com
#
# 2. ECS Task Role
# - resource "aws_iam_role" "task_role"
# - Permissions: Application-specific (DynamoDB, S3, etc.)
# - Trust: ecs-tasks.amazonaws.com
#
# 3. GitHub OIDC Provider
# - resource "aws_iam_openid_connect_provider" "github"
# - URL: https://token.actions.githubusercontent.com
# - Client ID: sts.amazonaws.com
# - Thumbprints: GitHub's certificate thumbprints
#
# 4. GitHub Actions Role
# - resource "aws_iam_role" "github_actions"
# - Trust policy: Scoped to specific GitHub org/repo
# - Permissions: ECR push/pull, ECS deploy, IAM PassRole
