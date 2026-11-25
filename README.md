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

```
terraform-aws-modules/
├── modules/
│   ├── networking/          # vpc, subnet, vpc_endpoints
│   ├── security/             # iam_role, iam_policy, security_group
│   ├── compute/              # ec2, asg, ecs_service
│   ├── storage/              # s3_bucket, rds_instance, dynamodb_table
│   └── observability/        # cloudwatch_log_group, cloudwatch_alarms
├── examples/
│   ├── single-vpc/
│   ├── ecs-service/
│   └── static-site-s3-cloudfront/
└── environments/
    ├── dev/
    ├── stage/
    └── prod/
```

## Requirements

- Terraform CLI 1.5+
- AWS account and credentials (IAM user or role)
- Optional: `tflint`, `checkov` / `tfsec`, `pre-commit`

## Getting Started

```bash
cd examples/single-vpc
terraform init
terraform plan
terraform apply
```

## Module Usage Examples

### VPC

```hcl
module "vpc" {
  source = "../modules/networking/vpc"

  name                 = "${var.project}-${var.environment}"
  cidr_block           = var.vpc_cidr_block
  az_count             = 3
  enable_nat_gateways  = true

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

### S3 Bucket

```hcl
module "logs_bucket" {
  source = "../modules/storage/s3_bucket"

  bucket_name             = "${var.project}-${var.environment}-logs"
  versioning_enabled      = true
  sse_algorithm           = "aws:kms"
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

## Conventions

- Modules accept `project`, `environment`, and naming inputs for consistent resource names.
- Every resource supports a `tags` map.
- Defaults favor private networking, encryption, restricted security groups, and least-privilege IAM.
- Pin module versions when consuming from a registry or Git ref.

## Development

```bash
terraform fmt -recursive
terraform validate
tflint
checkov -d .
```

## License

MIT. See [LICENSE](LICENSE).
