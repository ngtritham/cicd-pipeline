# CI/CD Pipeline Template for Node.js to AWS ECS

A production-ready template for deploying containerized Node.js applications to AWS ECS using GitHub Actions, Terraform, and security best practices.

> **Phase 1 Note**: This is currently Phase 1 with echo commands in workflows. The workflows demonstrate the complete pipeline structure and flow without actual implementation. Phase 2 will add full functionality.

## Overview

This template provides a complete CI/CD pipeline with:

- **Parallel Execution**: Build, security scanning, and tests run concurrently
- **Multi-Environment**: Separate deployments for dev, staging, and production
- **Security-First**: Three-layer security scanning (dependencies, containers, code)
- **Infrastructure as Code**: Terraform modules for AWS resources
- **Zero Long-Lived Credentials**: GitHub OIDC for secure AWS access
- **Approval Gates**: Manual approval required for staging and production

## Architecture

### CI/CD Workflow

```
┌─────────────────────────────────────────────────────────┐
│  Feature Branch Push (any branch except master)         │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │    PARALLEL EXECUTION              │
        │                                    │
   ┌────▼────┐  ┌──────────────┐  ┌────────▼────┐
   │  Build  │  │   Security   │  │  Unit Test  │
   │  Docker │  │   Scan (3x)  │  │    Jest     │
   └────┬────┘  └──────┬───────┘  └──────┬──────┘
        │              │                  │
        └──────────────┴──────────────────┘
                       │
                 ┌─────▼──────┐
                 │ Deploy Dev │
                 └────────────┘

┌─────────────────────────────────────────────────────────┐
│  Master Branch Push (PR merge)                          │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │                                    │
   ┌────▼────┐  ┌──────────────┐  ┌────────▼────┐
   │  Build  │  │   Security   │  │  Unit Test  │
   └────┬────┘  └──────┬───────┘  └──────┬──────┘
        │              │                  │
        └──────────────┴──────────────────┘
                       │
                 ┌─────▼──────┐
                 │ Deploy Dev │ (auto)
                 └─────┬──────┘
                       │
                ┌──────▼────────┐
                │ Deploy Staging│ (manual approval)
                └──────┬────────┘
                       │
                ┌──────▼──────────┐
                │ Deploy Production│ (manual approval)
                └─────────────────┘
```

### Technology Stack

- **Application**: Express.js REST API (Node.js 20.x)
- **Testing**: Jest with coverage
- **Security**: Snyk + Trivy + ESLint
- **Containers**: Docker multi-stage builds
- **Infrastructure**: Terraform (AWS ECS Fargate, ECR, VPC, ALB)
- **CI/CD**: GitHub Actions with reusable workflows
- **Authentication**: GitHub OIDC (no long-lived credentials)

## Quick Start

### Prerequisites

- Node.js 20.x (use nvm: `nvm use`)
- Docker Desktop
- AWS CLI v2
- Terraform
- GitHub CLI (gh)

### Phase 1: Test Pipeline Structure

1. Clone this repository:
```bash
git clone <your-repo-url>
cd cicd-pipeline
```

2. Create a feature branch and push:
```bash
git checkout -b feature/test-pipeline
git commit --allow-empty -m "Test pipeline structure"
git push origin feature/test-pipeline
```

3. Check GitHub Actions tab to see the workflow run with echo commands explaining each step.

4. Optionally, configure GitHub Environments to test approval gates:
   - Go to: Repository → Settings → Environments
   - Create: `dev`, `staging`, `production`
   - Set required reviewers for staging (1) and production (2)

### Phase 2: Full Implementation (Coming Soon)

See [docs/SETUP.md](docs/SETUP.md) for detailed setup instructions including:
- Terraform infrastructure deployment
- GitHub repository configuration
- Complete workflow implementation

## Project Structure

```
cicd-pipeline/
├── .github/workflows/          # GitHub Actions workflows (Phase 1: echo commands)
│   ├── default.yml             # Feature branch pipeline
│   ├── main.yml                # Master branch pipeline
│   └── reusable/               # Reusable workflow components
├── app/                        # Node.js application (Phase 1: placeholders)
├── docker/                     # Docker configurations (Phase 1: placeholders)
├── terraform/                  # Infrastructure as Code (Phase 1: placeholders)
│   ├── modules/                # Reusable Terraform modules
│   └── environments/           # Environment-specific configs
└── docs/                       # Documentation
```

## Workflows

### Default Workflow (Feature Branches)
**Trigger**: Push to any branch except master

**Jobs**:
1. **Build, Security Scan, Unit Test** (parallel)
2. **Deploy to Dev** (auto-trigger after step 1)

### Main Workflow (Master Branch)
**Trigger**: Push to master (PR merge)

**Jobs**:
1. **Build, Security Scan, Unit Test** (parallel)
2. **Deploy to Dev** (auto-trigger)
3. **Deploy to Staging** (manual approval)
4. **Deploy to Production** (manual approval)

See [docs/WORKFLOWS.md](docs/WORKFLOWS.md) for detailed workflow documentation.

## Security Scanning

Three layers of security scanning run in parallel:

1. **Snyk**: Dependency vulnerability scanning
2. **Trivy**: Container image scanning
3. **ESLint**: Code security analysis

Results are uploaded to GitHub Security tab (SARIF format).

## Infrastructure

Terraform modules for AWS resources:

- **ECR**: Container registry with image scanning
- **IAM**: Roles for ECS tasks and GitHub Actions (OIDC)
- **Networking**: VPC, subnets, ALB, security groups
- **ECS**: Fargate cluster, services, auto-scaling

See [docs/TERRAFORM_SETUP.md](docs/TERRAFORM_SETUP.md) for infrastructure details.

## Environment Configuration

| Environment | CPU  | Memory | Tasks | Auto-Scale | Approval |
|-------------|------|--------|-------|------------|----------|
| Dev         | 256  | 512 MB | 1     | 1-2        | None     |
| Staging     | 512  | 1 GB   | 2     | 2-4        | 1 reviewer |
| Production  | 1024 | 2 GB   | 3     | 3-10       | 2 reviewers |

## Documentation

- [Setup Guide](docs/SETUP.md) - Complete setup instructions
- [Terraform Guide](docs/TERRAFORM_SETUP.md) - Infrastructure deployment
- [GitHub Configuration](docs/GITHUB_SETUP.md) - Repository setup
- [Workflows](docs/WORKFLOWS.md) - Detailed workflow documentation

## Phase Roadmap

**Phase 1 (Current)**: ✅
- GitHub Actions workflows with echo commands
- Placeholder files for app, Docker, Terraform
- Complete project structure
- Documentation

**Phase 2 (Next)**:
- Implement actual workflow actions
- Complete Node.js application
- Complete Terraform infrastructure
- Full end-to-end testing

## License

MIT
