# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a CI/CD template project for deploying containerized Node.js applications to AWS ECS using GitHub Actions and Terraform. The project is currently in **Phase 1**: all workflows use echo commands to demonstrate pipeline structure. Phase 2 will add actual implementation.

## Current State (Phase 1)

All code files are **placeholders with TODO comments**:
- Application files (`app/`) contain only TODO comments explaining what will be implemented
- Docker files contain commented structure
- Terraform modules contain placeholder comments
- **Workflows contain echo commands only** - no actual builds, tests, or deployments occur

When making changes, maintain this placeholder approach until Phase 2 begins.

## Architecture Overview

### Two-Workflow Design

**default.yml** (feature branches):
- Triggers on any branch except `master`
- Parallel: Build + Security Scan (3 jobs) + Unit Test
- Sequential: Deploy to Dev (after parallel jobs complete)

**main.yml** (master branch):
- Triggers on push to `master`
- Same parallel jobs as default.yml
- Sequential: Deploy Dev → Deploy Staging (manual approval) → Deploy Production (manual approval)

**Critical**: Build, security-scan, and unit-test jobs have NO `needs` dependencies, so they run in parallel. Only deploy jobs use `needs` to create sequential flow.

### Reusable Workflow Pattern

All main workflows call reusable workflows in `.github/workflows/reusable/`:
- `build.yml` - Docker build + ECR push
- `security-scan.yml` - Contains 3 parallel jobs (snyk-scan, trivy-scan, eslint-scan)
- `unit-test.yml` - Jest tests with coverage
- `deploy-ecs.yml` - ECS deployment (accepts `environment` input: dev/staging/prod)

Reusable workflows enable DRY principle and consistent behavior across feature and master branches.

### Terraform Module Structure

Modules are organized by AWS service:
- `terraform/modules/ecr/` - Container registry
- `terraform/modules/iam/` - Roles + GitHub OIDC provider
- `terraform/modules/networking/` - VPC, subnets, ALB, security groups
- `terraform/modules/ecs/` - Fargate cluster, services, auto-scaling

Environments reference modules:
- `terraform/environments/dev/` - 256 CPU, 512 MB memory
- `terraform/environments/staging/` - 512 CPU, 1024 MB memory
- `terraform/environments/prod/` - 1024 CPU, 2048 MB memory

Each environment has separate Terraform state files in S3.

## Key Workflow Patterns

### Parallel Execution in security-scan.yml

The security-scan reusable workflow contains **3 separate jobs** (not steps):
```yaml
jobs:
  snyk-scan:
    # runs in parallel
  trivy-scan:
    # runs in parallel
  eslint-scan:
    # runs in parallel
```
All three run concurrently for speed.

### Manual Approval Gates

Staging and production deployments use GitHub Environments:
- Jobs specify `environment: staging` or `environment: production`
- GitHub pauses workflow until required reviewers approve
- Configured in: Repository → Settings → Environments

### GitHub OIDC Authentication (Phase 2)

Workflows authenticate to AWS using OpenID Connect (no long-lived credentials):
```yaml
permissions:
  id-token: write  # Required for OIDC
  contents: read
```
The `AWS_ROLE_ARN` secret contains the IAM role ARN to assume.

## Common Commands

### Testing Workflows (Phase 1)

```bash
# Test feature branch workflow
git checkout -b feature/test-pipeline
git commit --allow-empty -m "Test pipeline"
git push origin feature/test-pipeline

# Test master workflow with approvals
git checkout master
git merge feature/test-pipeline
git push origin master
```

### Terraform Operations (Phase 2)

```bash
# Deploy dev environment
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# Get outputs for GitHub secrets
terraform output -raw github_actions_role_arn
terraform output -raw ecr_repository_url
```

### GitHub Configuration (Phase 2)

```bash
# Set repository secrets
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::123456789012:role/github-actions-role"
gh secret set AWS_REGION --body "us-east-1"

# Set repository variables
gh variable set ECR_REGISTRY --body "123456789012.dkr.ecr.us-east-1.amazonaws.com"
gh variable set ECS_CLUSTER_NAME --body "cicd-template-cluster"
```

## Important Constraints

### Workflow File Locations

- Main workflows MUST be in `.github/workflows/` (default.yml, main.yml)
- Reusable workflows MUST be in `.github/workflows/reusable/`
- Reusable workflows are called with: `uses: ./.github/workflows/reusable/build.yml`

### Environment Naming

- Environments MUST be named exactly: `dev`, `staging`, `production`
- These names are used in:
  - Workflow `environment` fields
  - Terraform tfvars files
  - ECS service names (e.g., `cicd-template-app-service-dev`)

### Branch Triggers

- `default.yml` uses `branches-ignore: [master]` to run on all branches except master
- `main.yml` uses `branches: [master]` to run only on master
- Do not change these triggers without understanding the multi-environment deployment flow

## Phase Transition Notes

When transitioning from Phase 1 to Phase 2:

1. **Workflows**: Replace echo commands with actual GitHub Actions (e.g., `actions/checkout@v4`, `aws-actions/configure-aws-credentials@v4`)
2. **Application**: Implement Express.js app following structure in placeholder comments
3. **Terraform**: Replace TODO comments with actual resource definitions
4. **Testing**: Ensure workflows work end-to-end before considering Phase 1 complete

Maintain the same workflow structure and job names to preserve the documented architecture.

## Documentation

Comprehensive guides in `docs/`:
- `SETUP.md` - Complete setup for Phase 1 and Phase 2
- `TERRAFORM_SETUP.md` - Infrastructure deployment guide with cost estimates
- `GITHUB_SETUP.md` - Repository secrets, variables, OIDC configuration
- `WORKFLOWS.md` - Detailed workflow documentation with timing estimates

These docs are the source of truth for Phase 2 implementation details.
