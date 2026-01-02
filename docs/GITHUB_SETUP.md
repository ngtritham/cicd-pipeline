# GitHub Setup Guide

Configuration guide for GitHub repository settings, secrets, and environments.

> **Phase 1 Note**: Secrets and variables are not required for Phase 1. This guide is for Phase 2 implementation.

## Repository Configuration

### 1. Enable GitHub Actions

1. Go to: Repository → Settings → Actions → General
2. Under "Actions permissions", select: "Allow all actions and reusable workflows"
3. Under "Workflow permissions", select: "Read and write permissions"
4. Save changes

### 2. Configure Branch Protection (Optional but Recommended)

**Protect master branch:**
1. Go to: Repository → Settings → Branches
2. Click "Add branch protection rule"
3. Branch name pattern: `master`
4. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (at least 1)
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
5. Save changes

## Environment Setup

### Dev Environment

1. Go to: Repository → Settings → Environments
2. Click "New environment"
3. Name: `dev`
4. Click "Configure environment"
5. Protection rules: None (auto-deploy)
6. Environment secrets: (Phase 2)
7. Save

### Staging Environment

1. Create new environment
2. Name: `staging`
3. Protection rules:
   - ✅ Required reviewers: Select 1 reviewer
   - ✅ Prevent self-review (optional)
   - ✅ Wait timer: 0 minutes (or add delay if desired)
4. Deployment branches: Selected branches → `master`
5. Environment URL: `https://staging-app.example.com` (Phase 2)
6. Save

### Production Environment

1. Create new environment
2. Name: `production`
3. Protection rules:
   - ✅ Required reviewers: Select 2+ reviewers
   - ✅ Prevent self-review
   - ✅ Wait timer: Consider 5-10 minutes for production
4. Deployment branches: Selected branches → `master`
5. Environment URL: `https://app.example.com` (Phase 2)
6. Save

## Repository Secrets (Phase 2)

Secrets are encrypted and only exposed to workflows during execution.

### Required Secrets

**AWS_ROLE_ARN**
- Description: IAM role ARN for GitHub Actions (OIDC)
- Value: From Terraform output `github_actions_role_arn`
- Example: `arn:aws:iam::123456789012:role/github-actions-role`

```bash
# Get from Terraform
cd terraform/environments/dev
terraform output -raw github_actions_role_arn

# Set in GitHub
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::123456789012:role/github-actions-role"
```

**AWS_REGION**
- Description: AWS region for deployments
- Value: Your AWS region (e.g., `us-east-1`)

```bash
gh secret set AWS_REGION --body "us-east-1"
```

### Optional Secrets

**SNYK_TOKEN**
- Description: Snyk API token for vulnerability scanning
- Get token: https://app.snyk.io/account (create free account)

```bash
gh secret set SNYK_TOKEN --body "your-snyk-token"
```

### Verify Secrets

```bash
# List all secrets
gh secret list
```

## Repository Variables (Phase 2)

Variables are plaintext configuration values.

### Required Variables

**ECR_REGISTRY**
- Description: ECR registry URL
- Value: From Terraform output

```bash
# Get from Terraform
terraform output -raw ecr_repository_url | cut -d'/' -f1

# Set in GitHub
gh variable set ECR_REGISTRY --body "123456789012.dkr.ecr.us-east-1.amazonaws.com"
```

**ECS_CLUSTER_NAME**
- Description: ECS cluster name
- Value: From Terraform output

```bash
# Get from Terraform
terraform output -raw cluster_name

# Set in GitHub
gh variable set ECS_CLUSTER_NAME --body "cicd-template-cluster"
```

**NODE_VERSION**
- Description: Node.js version for workflows
- Value: `20.11.0` (matches .nvmrc)

```bash
gh variable set NODE_VERSION --body "20.11.0"
```

### Verify Variables

```bash
# List all variables
gh variable list
```

## GitHub OIDC Provider Setup

GitHub uses OpenID Connect (OIDC) to authenticate with AWS without long-lived credentials.

### How It Works

1. GitHub Actions requests a token from GitHub's OIDC provider
2. GitHub issues a short-lived JWT token
3. Workflow presents token to AWS STS
4. AWS validates token against configured OIDC provider
5. AWS returns temporary credentials for the configured IAM role
6. Workflow uses temporary credentials to deploy

### Benefits

- ✅ No long-lived credentials stored in GitHub
- ✅ Automatic credential rotation
- ✅ Scoped to specific repository
- ✅ Auditable via CloudTrail
- ✅ Follows AWS security best practices

### Verification

After Terraform deployment, verify OIDC setup:

```bash
# Check OIDC provider exists
aws iam list-open-id-connect-providers

# Check role trust policy
aws iam get-role --role-name github-actions-role
```

The trust policy should allow GitHub's OIDC provider and be scoped to your repository.

## Workflow Permissions

Each workflow requires specific permissions:

### Build Workflow
- `id-token: write` - For OIDC authentication
- `contents: read` - For checking out code

### Deploy Workflow
- `id-token: write` - For OIDC authentication
- `contents: read` - For checking out code

Permissions are set at the job level in workflow files.

## Security Best Practices

### Secrets Management

1. **Never commit secrets to repository**
   - Use GitHub Secrets for sensitive values
   - Add `.env` files to `.gitignore`

2. **Use least privilege**
   - Grant minimum required permissions
   - Scope secrets to specific environments if possible

3. **Rotate secrets regularly**
   - Rotate tokens every 90 days
   - Use AWS IAM roles instead of access keys

4. **Audit secret usage**
   - Review workflow runs regularly
   - Check CloudTrail for AWS API calls

### Environment Protection

1. **Use required reviewers**
   - Staging: At least 1 reviewer
   - Production: At least 2 reviewers

2. **Limit deployment branches**
   - Only allow deployments from `master`
   - Prevent accidental deployments from feature branches

3. **Add wait timers**
   - Consider 5-10 minute wait for production
   - Allows time to cancel if needed

## Troubleshooting

### Common Issues

**OIDC authentication fails:**
- Check `AWS_ROLE_ARN` secret is correct
- Verify OIDC provider exists in AWS
- Check role trust policy includes your repository
- Ensure `id-token: write` permission is set

**Workflow can't access secrets:**
- Verify secret exists: `gh secret list`
- Check secret name matches workflow exactly (case-sensitive)
- Confirm secret is set at repository level (not environment)

**Environment deployment not triggering:**
- Check environment name matches workflow exactly
- Verify deployment branch rules
- Confirm required reviewers are configured

**Permission denied errors:**
- Check IAM role permissions
- Verify workflow has `contents: read` permission
- Review CloudWatch logs for details

### Useful Commands

```bash
# View workflow runs
gh run list

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log

# Re-run failed workflow
gh run rerun <run-id>

# List secrets
gh secret list

# Delete secret
gh secret delete SECRET_NAME

# List variables
gh variable list

# Update variable
gh variable set VAR_NAME --body "new-value"
```

## Post-Setup Verification

### 1. Test OIDC Authentication

Create a simple workflow to test AWS authentication:

```yaml
name: Test OIDC
on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Verify AWS identity
        run: aws sts get-caller-identity
```

### 2. Test Environment Approval

1. Push to master branch
2. Watch workflow run
3. Verify approval request appears for staging
4. Approve and verify deployment continues
5. Verify approval request appears for production

### 3. Verify Outputs

Check that workflows produce expected outputs:
- Build job outputs image URI
- Security scans upload SARIF results
- Deployments complete successfully

## Next Steps

1. Review [WORKFLOWS.md](WORKFLOWS.md) for detailed workflow documentation
2. Test the complete CI/CD pipeline end-to-end
3. Monitor first production deployment
4. Set up CloudWatch alarms and dashboards
5. Configure notification integrations (Slack, email)

## Additional Resources

- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
