# TODO: Create ECR repository
#
# Phase 2 implementation will include:
# - resource "aws_ecr_repository" "app"
# - Private repository: var.repository_name
# - Image tag mutability: MUTABLE
# - Image scanning on push: enabled
# - Encryption: AES256
# - Lifecycle policy to keep last 10 images
# - Tags for organization and cost tracking
