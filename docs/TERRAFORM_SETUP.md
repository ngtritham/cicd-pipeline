# Terraform Setup Guide

Infrastructure deployment guide using Terraform for AWS resources.

> **Phase 1 Note**: All Terraform files are currently placeholders. This documentation describes what will be implemented in Phase 2.

## Overview

This template uses Terraform to provision:
- **ECR**: Docker container registry with image scanning
- **IAM**: Roles for ECS tasks and GitHub Actions (OIDC)
- **Networking**: VPC, subnets, ALB, security groups
- **ECS**: Fargate cluster, services, and auto-scaling

## Architecture

### Module Organization

```
terraform/
├── modules/              # Reusable modules
│   ├── ecr/             # Container registry
│   ├── iam/             # Roles and OIDC provider
│   ├── networking/      # VPC, subnets, ALB
│   └── ecs/             # Cluster, services, auto-scaling
└── environments/        # Environment-specific configs
    ├── dev/             # Dev environment
    ├── staging/         # Staging environment
    └── prod/            # Production environment
```

### Network Architecture

```
VPC: 10.0.0.0/16
├── Public Subnets (for ALB)
│   ├── 10.0.1.0/24 (us-east-1a)
│   └── 10.0.2.0/24 (us-east-1b)
├── Private Subnets (for ECS tasks)
│   ├── 10.0.11.0/24 (us-east-1a)
│   └── 10.0.12.0/24 (us-east-1b)
├── Internet Gateway (for public subnets)
└── NAT Gateway (for private subnet internet access)
```

## Terraform Modules

### ECR Module

**Purpose**: Creates private Docker container registry

**Resources**:
- ECR repository with image scanning enabled
- Lifecycle policy to retain last 10 images
- Encryption at rest

**Outputs**:
- `repository_url`: ECR repository URL for Docker push
- `repository_arn`: ARN for IAM policies

### IAM Module

**Purpose**: Creates IAM roles and OIDC provider for GitHub Actions

**Resources**:
1. **ECS Task Execution Role**
   - Permissions: Pull ECR images, write CloudWatch logs
   - Trust: ecs-tasks.amazonaws.com

2. **ECS Task Role**
   - Permissions: Application-specific (DynamoDB, S3, etc.)
   - Trust: ecs-tasks.amazonaws.com

3. **GitHub OIDC Provider**
   - URL: https://token.actions.githubusercontent.com
   - Audience: sts.amazonaws.com

4. **GitHub Actions Role**
   - Trust: Scoped to specific GitHub org/repo
   - Permissions: ECR push/pull, ECS deploy

**Outputs**:
- `github_actions_role_arn`: For GitHub secrets
- `task_execution_role_arn`: For ECS task definitions
- `task_role_arn`: For ECS task definitions

### Networking Module

**Purpose**: Creates VPC infrastructure

**Resources**:
- VPC with DNS enabled
- 2 public subnets (different AZs)
- 2 private subnets (different AZs)
- Internet Gateway
- NAT Gateway with Elastic IP
- Route tables
- Security groups (ALB and ECS)

**Outputs**:
- `vpc_id`: VPC identifier
- `public_subnet_ids`: For ALB placement
- `private_subnet_ids`: For ECS task placement
- Security group IDs

### ECS Module

**Purpose**: Creates ECS cluster and services

**Resources**:
- ECS Fargate cluster
- Application Load Balancer (ALB)
- Target groups (one per environment)
- ECS task definitions
- ECS services with rolling updates
- Auto-scaling policies
- CloudWatch log groups

**Outputs**:
- `cluster_arn`: ECS cluster identifier
- `service_name`: For GitHub Actions deployment
- `alb_dns_name`: Application URL

## Environment Configuration

### Dev Environment

**Resource Sizing**:
- Task CPU: 256 (.25 vCPU)
- Task Memory: 512 MB
- Desired count: 1 task
- Auto-scaling: 1-2 tasks

**Cost**: ~$9/month

### Staging Environment

**Resource Sizing**:
- Task CPU: 512 (.5 vCPU)
- Task Memory: 1024 MB
- Desired count: 2 tasks
- Auto-scaling: 2-4 tasks

**Cost**: ~$36/month

### Production Environment

**Resource Sizing**:
- Task CPU: 1024 (1 vCPU)
- Task Memory: 2048 MB
- Desired count: 3 tasks
- Auto-scaling: 3-10 tasks

**Cost**: ~$108/month

## Deployment Order (Phase 2)

### Prerequisites

1. **Create S3 Backend** (for Terraform state):
```bash
aws s3 mb s3://cicd-template-terraform-state
aws s3api put-bucket-versioning \
  --bucket cicd-template-terraform-state \
  --versioning-configuration Status=Enabled
```

2. **Create DynamoDB Table** (for state locking):
```bash
aws dynamodb create-table \
  --table-name cicd-template-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### Step 1: Deploy Dev Environment

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply infrastructure
terraform apply

# Save outputs
terraform output -json > ../../../aws-outputs-dev.json
```

### Step 2: Deploy Staging Environment

```bash
cd terraform/environments/staging
terraform init
terraform plan
terraform apply
terraform output -json > ../../../aws-outputs-staging.json
```

### Step 3: Deploy Production Environment

```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
terraform output -json > ../../../aws-outputs-prod.json
```

## State Management

### Backend Configuration

Each environment uses S3 backend with different state files:
- Dev: `s3://bucket/dev/terraform.tfstate`
- Staging: `s3://bucket/staging/terraform.tfstate`
- Prod: `s3://bucket/prod/terraform.tfstate`

### State Locking

DynamoDB table prevents concurrent modifications:
- Table: `cicd-template-terraform-locks`
- Lock ID: Unique per state file

## Cost Estimation

### Monthly AWS Costs (us-east-1)

**Networking**:
- VPC: Free
- NAT Gateway: ~$32/month
- ALB: ~$16/month

**ECS Fargate** (all environments):
- Dev: ~$9/month
- Staging: ~$36/month
- Production: ~$108/month

**ECR**:
- Storage: ~$0.10/GB/month
- Data transfer: Varies

**CloudWatch**:
- Logs: ~$5/month
- Metrics: Included

**Total Estimated Cost**: ~$175-200/month

### Cost Optimization Tips

1. Use Fargate Spot for dev/staging (70% savings)
2. Configure log retention policies
3. Schedule dev environment to stop nights/weekends
4. Use ECR lifecycle policies
5. Review and remove unused resources

## Security Best Practices

### IAM Roles

- Least privilege principle
- Separate roles per environment
- No long-lived credentials
- Regular access reviews

### Network Security

- ECS tasks in private subnets
- ALB in public subnets
- Security groups with minimal access
- VPC endpoints for AWS services (optional)

### Encryption

- ECR encryption at rest (AES256)
- ECS task encryption in transit
- ALB HTTPS (Phase 2: add ACM certificate)

## Troubleshooting

### Common Issues

**Terraform init fails**:
- Check AWS credentials: `aws sts get-caller-identity`
- Verify S3 bucket exists and is accessible
- Check network connectivity

**Plan shows unexpected changes**:
- Review state file
- Check for manual changes in AWS console
- Verify variable values

**Apply fails with permissions**:
- Check IAM permissions for your AWS user
- Verify service limits not exceeded
- Review CloudWatch logs for errors

### Useful Commands

```bash
# View current state
terraform show

# Import existing resource
terraform import aws_ecr_repository.app repository-name

# Remove resource from state
terraform state rm aws_instance.example

# Refresh state
terraform refresh

# Destroy all resources
terraform destroy
```

## Next Steps

1. Review Terraform module structure in `terraform/modules/`
2. Customize environment configurations in `terraform/environments/`
3. Plan S3 backend and DynamoDB table names
4. Prepare AWS account with appropriate permissions
5. See [GITHUB_SETUP.md](GITHUB_SETUP.md) for post-deployment configuration

## Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform Backend Configuration](https://www.terraform.io/docs/language/settings/backends/index.html)
