# Setup Guide

Complete setup instructions for the CI/CD Pipeline Template.

## Prerequisites

### Required Tools

- **Node.js 20.x**: Use nvm for version management
  ```bash
  nvm install 20.11.0
  nvm use 20.11.0
  ```

- **Docker Desktop**: For local container development
  - Download from: https://www.docker.com/products/docker-desktop

- **AWS CLI v2**: For AWS resource management
  ```bash
  # macOS
  brew install awscli

  # Verify installation
  aws --version
  ```

- **Terraform**: For infrastructure as code
  ```bash
  # macOS
  brew install terraform

  # Verify installation
  terraform --version
  ```

- **GitHub CLI (gh)**: For GitHub repository management
  ```bash
  # macOS
  brew install gh

  # Verify installation
  gh --version
  ```

### AWS Account

- Active AWS account with appropriate permissions
- Ability to create:
  - ECR repositories
  - ECS clusters and services
  - VPC and networking resources
  - IAM roles and OIDC providers
  - CloudWatch log groups

## Phase 1 Setup (Current)

Phase 1 focuses on understanding the pipeline structure using echo commands.

### Step 1: Clone Repository

```bash
git clone <your-repo-url>
cd cicd-pipeline
```

### Step 2: Review Project Structure

Explore the project files:
- `.github/workflows/` - Workflow definitions with echo commands
- `app/` - Placeholder application files
- `terraform/` - Placeholder infrastructure modules
- `docker/` - Placeholder Docker configurations

### Step 3: Configure GitHub Environments (Optional)

To test manual approval gates:

1. Navigate to your GitHub repository
2. Go to: Settings → Environments
3. Create three environments:

**Dev Environment:**
- Name: `dev`
- Protection rules: None

**Staging Environment:**
- Name: `staging`
- Required reviewers: 1 person
- Deployment branches: `master` only

**Production Environment:**
- Name: `production`
- Required reviewers: 2 people
- Deployment branches: `master` only

### Step 4: Test Workflows

**Test Feature Branch Workflow:**
```bash
# Create a feature branch
git checkout -b feature/test-pipeline

# Make a commit (can be empty)
git commit --allow-empty -m "Test pipeline structure"

# Push to GitHub
git push origin feature/test-pipeline
```

Check GitHub Actions tab to see the workflow run. You'll see echo messages explaining each step.

**Test Master Branch Workflow (with approvals):**
```bash
# Switch to master
git checkout master

# Merge feature branch
git merge feature/test-pipeline

# Push to master
git push origin master
```

If you configured environments with reviewers, you'll see approval requests for staging and production deployments.

### Step 5: Review Workflow Output

1. Go to GitHub Actions tab
2. Click on the workflow run
3. Expand each job to see echo command output
4. Observe:
   - Build, Security Scan, Unit Test run in parallel
   - Deploy jobs run sequentially
   - Approval gates pause the pipeline

## Phase 2 Setup (Coming Soon)

Phase 2 will involve actual implementation.

### Infrastructure Deployment

See [TERRAFORM_SETUP.md](TERRAFORM_SETUP.md) for:
- Terraform backend configuration
- Module deployment order
- Environment-specific configurations

### GitHub Configuration

See [GITHUB_SETUP.md](GITHUB_SETUP.md) for:
- Repository secrets
- Repository variables
- OIDC provider setup

### Application Deployment

1. Build Docker image locally
2. Test application endpoints
3. Push to ECR
4. Deploy to ECS

## Troubleshooting

### Common Issues

**Workflow doesn't trigger:**
- Check branch name (should not be `master` for default workflow)
- Verify GitHub Actions is enabled in repository settings
- Check workflow file syntax

**Approval not requested:**
- Verify environment is created
- Check required reviewers are configured
- Ensure branch protection allows deployment

**Permission errors:**
- Verify your GitHub account has appropriate permissions
- Check repository settings allow Actions

## Next Steps

1. Review workflow output to understand pipeline flow
2. Read [WORKFLOWS.md](WORKFLOWS.md) for detailed workflow documentation
3. Prepare for Phase 2 by reviewing [TERRAFORM_SETUP.md](TERRAFORM_SETUP.md)
4. Plan your AWS account setup

## Support

For issues or questions:
- Check GitHub Issues in this repository
- Review workflow logs in GitHub Actions
- Consult the documentation in `docs/` folder
