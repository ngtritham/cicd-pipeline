# Workflows Documentation

Detailed documentation for GitHub Actions workflows.

> **Phase 1 Note**: All workflows currently use echo commands to demonstrate structure. Phase 2 will implement actual functionality.

## Overview

This template includes two main workflows and four reusable workflows:

**Main Workflows:**
- `default.yml` - Feature branch CI/CD
- `main.yml` - Production CI/CD with approvals

**Reusable Workflows:**
- `build.yml` - Docker build and ECR push
- `security-scan.yml` - Security scanning (3 parallel jobs)
- `unit-test.yml` - Jest unit tests with coverage
- `deploy-ecs.yml` - ECS deployment with OIDC

## Workflow Architecture

### Parallel vs Sequential Execution

```
PARALLEL EXECUTION (Jobs with no dependencies)
┌─────────┐  ┌──────────────┐  ┌───────────┐
│  Build  │  │ Security Scan│  │ Unit Test │
│         │  │   (3 jobs)   │  │           │
└─────────┘  └──────────────┘  └───────────┘

SEQUENTIAL EXECUTION (Jobs with 'needs')
┌────────────┐
│ Deploy Dev │  (needs: [build, security-scan, unit-test])
└─────┬──────┘
      │
┌─────▼────────┐
│Deploy Staging│ (needs: deploy-dev)
└─────┬────────┘
      │
┌─────▼─────────┐
│Deploy Prod    │ (needs: deploy-staging)
└───────────────┘
```

## Default Workflow (Feature Branches)

**File**: `.github/workflows/default.yml`

**Trigger**: Push to any branch except `master`

```yaml
on:
  push:
    branches-ignore:
      - master
```

### Jobs

#### 1. Build (Parallel)
**Purpose**: Build Docker image and push to ECR

**Steps** (Phase 1 - echo commands):
1. Checkout code
2. Set up Docker Buildx
3. Configure AWS credentials (OIDC)
4. Login to ECR
5. Build Docker image
6. Push to ECR
7. Output image URI

**Duration**: ~5-8 minutes (Phase 2)

#### 2. Security Scan (Parallel)
**Purpose**: Three-layer security scanning

**Sub-jobs** (all parallel):

**2a. Snyk Scan**
- Scan package.json for dependency vulnerabilities
- Severity threshold: HIGH
- Output: SARIF format

**2b. Trivy Scan**
- Scan Docker image for OS/library vulnerabilities
- Check for: CRITICAL, HIGH
- Output: SARIF format

**2c. ESLint Scan**
- Scan source code for security issues
- Using: eslint-plugin-security
- Output: SARIF format

**Duration**: ~3-5 minutes (Phase 2)

#### 3. Unit Test (Parallel)
**Purpose**: Run Jest tests with coverage

**Steps** (Phase 1 - echo commands):
1. Checkout code
2. Set up Node.js
3. Cache dependencies
4. Install dependencies
5. Run tests
6. Generate coverage
7. Upload coverage artifacts

**Duration**: ~2-3 minutes (Phase 2)

#### 4. Deploy Dev (Sequential)
**Purpose**: Deploy to dev environment

**Depends on**: build, security-scan, unit-test (all must succeed)

**Steps** (Phase 1 - echo commands):
1. Checkout code
2. Configure AWS credentials (OIDC)
3. Login to ECR
4. Render ECS task definition
5. Register task definition
6. Deploy to ECS
7. Verify deployment

**Duration**: ~3-5 minutes (Phase 2)

### Total Workflow Duration

- Parallel jobs: ~5-8 minutes (longest of build/scan/test)
- Deploy dev: ~3-5 minutes
- **Total**: ~8-13 minutes (Phase 2)

## Main Workflow (Master Branch)

**File**: `.github/workflows/main.yml`

**Trigger**: Push to `master` branch (typically from PR merge)

```yaml
on:
  push:
    branches:
      - master
```

### Jobs

Jobs 1-4 are identical to Default Workflow.

#### 5. Deploy Staging (Sequential)
**Purpose**: Deploy to staging environment with approval

**Depends on**: deploy-dev

**Environment**: `staging`
- Required reviewers: 1
- Manual approval required

**Steps**: Same as deploy-dev but for staging

**Duration**: ~3-5 minutes + approval time

#### 6. Deploy Production (Sequential)
**Purpose**: Deploy to production environment with approval

**Depends on**: deploy-staging

**Environment**: `production`
- Required reviewers: 2
- Manual approval required

**Steps**: Same as deploy-dev but for production

**Duration**: ~3-5 minutes + approval time

### Total Workflow Duration

- Parallel jobs: ~5-8 minutes
- Deploy dev: ~3-5 minutes
- Deploy staging: ~3-5 minutes + approval
- Deploy production: ~3-5 minutes + approval
- **Total**: ~14-23 minutes + approval times (Phase 2)

## Reusable Workflows

### Build Workflow

**File**: `.github/workflows/reusable/build.yml`

**Called by**: default.yml, main.yml

**Key Features** (Phase 2):
- Multi-stage Docker build
- Layer caching using GitHub Actions cache
- Tagging: commit SHA + latest
- ECR push
- Output image URI for downstream jobs

**Permissions Required**:
```yaml
permissions:
  id-token: write  # For OIDC
  contents: read   # For checkout
```

**Environment Variables Used**:
- `${{ secrets.AWS_ROLE_ARN }}`
- `${{ secrets.AWS_REGION }}`
- `${{ vars.ECR_REGISTRY }}`

### Security Scan Workflow

**File**: `.github/workflows/reusable/security-scan.yml`

**Called by**: default.yml, main.yml

**Key Features** (Phase 2):
- Three parallel security scans
- SARIF upload to GitHub Security tab
- Fail on HIGH/CRITICAL vulnerabilities

**Jobs**:
1. **snyk-scan**: Dependency scanning
2. **trivy-scan**: Container scanning
3. **eslint-scan**: Code security scanning

All jobs run in parallel for speed.

**Environment Variables Used**:
- `${{ secrets.SNYK_TOKEN }}` (optional)
- `${{ vars.ECR_REGISTRY }}`

### Unit Test Workflow

**File**: `.github/workflows/reusable/unit-test.yml`

**Called by**: default.yml, main.yml

**Key Features** (Phase 2):
- Node.js setup from .nvmrc
- Dependency caching
- Jest with coverage
- Coverage artifact upload
- Fail if coverage < 80%

**Environment Variables Used**:
- `${{ vars.NODE_VERSION }}` (optional, defaults to .nvmrc)

### Deploy ECS Workflow

**File**: `.github/workflows/reusable/deploy-ecs.yml`

**Called by**: default.yml, main.yml

**Inputs**:
```yaml
inputs:
  environment:
    required: true
    type: string
    description: 'dev, staging, or production'
```

**Key Features** (Phase 2):
- OIDC authentication (no long-lived credentials)
- ECS task definition rendering
- Rolling deployment
- Health check verification
- Environment-specific configuration

**Permissions Required**:
```yaml
permissions:
  id-token: write  # For OIDC
  contents: read   # For checkout
```

**Environment Variables Used**:
- `${{ secrets.AWS_ROLE_ARN }}`
- `${{ secrets.AWS_REGION }}`
- `${{ vars.ECR_REGISTRY }}`
- `${{ vars.ECS_CLUSTER_NAME }}`

## Manual Approval Process

### How Approvals Work

1. Workflow reaches deployment job with `environment` setting
2. GitHub pauses execution
3. Configured reviewers receive notification
4. Reviewers can:
   - Approve deployment
   - Reject deployment
   - Comment before deciding
5. After approval(s) received, deployment continues

### Approval Configuration

Set in: Repository → Settings → Environments → {env} → Required reviewers

**Staging**:
- Required: 1 reviewer
- Prevents self-review: Optional
- Wait timer: 0 minutes (instant approval)

**Production**:
- Required: 2 reviewers
- Prevents self-review: Recommended
- Wait timer: 5-10 minutes (gives time to cancel)

### Approval Best Practices

1. **Review before approving**:
   - Check build succeeded
   - Review security scan results
   - Verify test coverage
   - Check deployment logs

2. **Use comments**:
   - Ask questions before approving
   - Document approval reasoning
   - Note any concerns

3. **Monitor deployment**:
   - Watch deployment logs
   - Check CloudWatch for errors
   - Verify health checks pass

## Workflow Triggers

### Push Triggers

**Default Workflow**:
```yaml
on:
  push:
    branches-ignore:
      - master
```
Runs on any push except to master.

**Main Workflow**:
```yaml
on:
  push:
    branches:
      - master
```
Runs only on push to master.

### Manual Triggers (Phase 2)

Add `workflow_dispatch` for manual runs:

```yaml
on:
  push:
    branches: [master]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - staging
          - production
```

## Workflow Outputs

### Build Workflow Outputs

```yaml
outputs:
  image-uri:
    description: "ECR image URI with tag"
    value: ${{ jobs.build.outputs.image-uri }}
```

Used by deploy workflows to know which image to deploy.

### Security Scan Outputs

- SARIF files uploaded to GitHub Security tab
- Viewable at: Repository → Security → Code scanning alerts

### Test Outputs

- Coverage reports as artifacts
- Downloadable from workflow run page

## Debugging Workflows

### View Workflow Runs

```bash
# List recent runs
gh run list

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log

# Download artifacts
gh run download <run-id>
```

### Common Issues

**Workflow doesn't trigger**:
- Check branch name
- Verify GitHub Actions enabled
- Check workflow file syntax

**Job fails**:
- Expand job in GitHub UI
- Check error message
- Review CloudWatch logs (for AWS errors)

**Approval not requested**:
- Verify environment configured
- Check required reviewers set
- Ensure deployment branch matches

## Workflow Best Practices

### 1. Use Reusable Workflows

Benefits:
- DRY (Don't Repeat Yourself)
- Single source of truth
- Easier maintenance
- Consistent behavior

### 2. Maximize Parallelization

- Run independent jobs in parallel
- Only use `needs` when truly dependent
- Reduces total workflow time

### 3. Cache Dependencies

- Cache npm modules
- Cache Docker layers
- Reduces build time and costs

### 4. Fail Fast

- Run quick checks first (lint, type check)
- Run expensive operations last (deploy)
- Cancel workflow on first failure

### 5. Use Environments

- Separate dev/staging/prod
- Require approvals for production
- Use environment-specific secrets/variables

## Next Steps

1. Test workflows with feature branch push
2. Test approval flow with master push
3. Review workflow run times
4. Optimize slow steps
5. Set up workflow notifications (Slack, email)
6. Monitor workflow success rates

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Environment Protection Rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
