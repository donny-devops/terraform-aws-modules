# Terraform AWS Modules

[![Security Hygiene](https://github.com/donny-devops/terraform-aws-modules/actions/workflows/security-hygiene.yml/badge.svg)](https://github.com/donny-devops/terraform-aws-modules/actions/workflows/security-hygiene.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-232F3E?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)


A collection of **reusable, opinionated Terraform modules** for provisioning AWS infrastructure in a consistent, composable way.

## Overview

This repository provides building blocks for common AWS primitives (networking, compute, storage, security, and observability) so that environments can be created quickly with minimal repetition and strong defaults.

Each module aims to be:
- **Composable** — small, focused building blocks that can be combined
- **Configurable** — sane defaults with overrideable inputs
- **Secure-by-default** — least-privilege IAM, encryption, logging, and tagging
- **Documented** — clear input/output variables and examples

## Goals

- Standardize AWS infrastructure across projects and environments
- Reduce copy-paste Terraform code and module drift
- Encourage best practices around IAM, networking, logging, and tagging
- Make it easy to spin up dev/stage/prod with minimal changes

## Repository Structure

```bash
aws-terraform-modules/
├── README.md
├── modules/
│   ├── networking/
│   │   ├── vpc/
│   │   ├── subnet/
│   │   └── vpc_endpoints/
│   ├── security/
│   │   ├── iam_role/
│   │   ├── iam_policy/
│   │   └── security_group/
│   ├── compute/
│   │   ├── ec2/
│   │   ├── asg/
│   │   └── ecs_service/
│   ├── storage/
│   │   ├── s3_bucket/
│   │   ├── rds_instance/
│   │   └── dynamodb_table/
│   ├── observability/
│   │   ├── cloudwatch_log_group/
│   │   └── cloudwatch_alarms/
│   └── networking_baseline/
├── examples/
│   ├── single-vpc/
│   ├── ecs-service/
│   └── static-site-s3-cloudfront/
├── environments/
│   ├── dev/
│   ├── stage/
│   └── prod/
└── terraform.tfvars.example
```

> Adjust modules and examples to match your actual layout.

## Requirements

- Terraform CLI 1.5+
- AWS account and credentials (IAM user or role)
- Optional: `tflint`, `tfsec` / `checkov`, `pre-commit` for validation

## Getting Started

### 1. Initialize Terraform

From any example or consumer root module:

```bash
cd examples/single-vpc
terraform init
```

### 2. Review Variables

Inspect `variables.tf` and `terraform.tfvars.example` for required inputs such as:

- `aws_region`
- `project`
- `environment`
- CIDR ranges and subnet configuration

Create your own `terraform.tfvars` (or use `-var-file`):

```hcl
aws_region     = "us-east-1"
project        = "my-project"
environment    = "dev"
vpc_cidr_block = "10.0.0.0/16"
```

### 3. Plan and Apply

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Or directly:

```bash
terraform apply
```

## Module Usage

### Example: VPC Module

```hcl
module "vpc" {
  source = "../modules/networking/vpc"

  name               = "${var.project}-${var.environment}"
  cidr_block         = var.vpc_cidr_block
  az_count           = 3
  enable_nat_gateways = true

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

### Example: S3 Bucket Module

```hcl
module "logs_bucket" {
  source = "../modules/storage/s3_bucket"

  bucket_name             = "${var.project}-${var.environment}-logs"
  versioning_enabled      = true
  force_destroy           = false
  sse_algorithm           = "aws:kms"
  enable_access_logging   = true
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Project     = var.project
    Environment = var.environment
    DataClass   = "logs"
  }
}
```

## Conventions & Best Practices

- **Naming**: modules should accept `project`, `environment`, and `name` or `suffix` inputs for consistent resource naming
- **Tagging**: every resource should support a `tags` map and merge common tags
- **Security**: default to private subnets, restricted security groups, encrypted storage, and least-privilege IAM policies
- **Observability**: where applicable, enable CloudWatch logs, metrics, and alarms
- **Inputs/Outputs**: expose only what callers need (e.g., IDs, ARNs, endpoints)

### Versioning

- Use semantic versioning for this module library (e.g., tags like `v0.1.0`)
- Consumers should pin module versions using `ref` or a registry version when publishing

## Development

### Linting and Validation

Suggested tools:

```bash
terraform fmt -recursive
terraform validate
tflint
tfsec   # or: checkov
```

Example `pre-commit` usage:

```bash
pre-commit install
pre-commit run --all-files
```

### Testing

- Use `terraform plan` in CI to detect drift and breaking changes
- For critical modules, consider Terratest or similar tools for automated tests

## Environments

The `environments/` directory can hold root modules for `dev`, `stage`, and `prod` that compose shared modules with environment-specific values.

Example structure:

```bash
environments/dev/
├── main.tf
├── variables.tf
└── terraform.tfvars
```

## Roadmap

- Add more AWS service modules (EKS, Lambda, API Gateway, CloudFront, etc.)
- Add opinionated blueprints (e.g., “ECS service behind ALB”, “Serverless API”)
- Publish selected modules to a Terraform registry namespace
- Add CI workflows for format, validate, lint, and security checks
- Add documentation site or module registry docs

## License

Choose a license that fits your intended use, such as MIT, Apache-2.0, or a private internal license.
