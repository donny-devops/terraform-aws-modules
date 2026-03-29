# terraform-aws-modules

Production-ready, reusable Terraform modules for AWS infrastructure. Covers VPC networking, ECS Fargate services, and RDS PostgreSQL — composable and security-hardened out of the box.

[![Terraform CI](https://github.com/donny-devops/terraform-aws-modules/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/donny-devops/terraform-aws-modules/actions/workflows/terraform-ci.yml)
[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A51.5-7B42BC?style=flat-square&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Multi--AZ-232F3E?style=flat-square&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

---

## Modules

| Module | Description | Key Resources |
|--------|-------------|---------------|
| [`vpc`](modules/vpc/) | Multi-AZ VPC with public/private subnets | VPC, subnets, NAT gateways, route tables, flow logs |
| [`ecs`](modules/ecs/) | ECS Fargate cluster + service + autoscaling | Cluster, task definition, service, IAM roles, CloudWatch logs |
| [`rds`](modules/rds/) | RDS PostgreSQL with backups and encryption | DB instance, subnet group, security group, parameter group |

---

## Quick Usage

### VPC

```hcl
module "vpc" {
  source = "github.com/donny-devops/terraform-aws-modules//modules/vpc"

  name                 = "my-app"
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway   = true
}
```

### RDS PostgreSQL

```hcl
module "rds" {
  source = "github.com/donny-devops/terraform-aws-modules//modules/rds"

  name            = "my-app-db"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  database_name   = "appdb"
  master_username = "appuser"
  master_password = var.db_password
}
```

### ECS Fargate

```hcl
module "ecs" {
  source = "github.com/donny-devops/terraform-aws-modules//modules/ecs"

  name            = "my-app"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  container_image = "ghcr.io/org/app:latest"
  container_port  = 8080
}
```

---

## Complete Example

See [`examples/complete/`](examples/complete/) for a fully composed example that wires all three modules together with SSM Parameter Store for secrets injection.

---

## Requirements

| Tool | Version |
|------|---------|
| Terraform | >= 1.5 |
| AWS Provider | >= 5.0 |
| AWS CLI | >= 2.0 |

---

## CI Pipeline

The GitHub Actions CI pipeline runs on all PRs and enforces:

1. `terraform fmt -check` — formatting consistency
2. `terraform validate` — configuration validity
3. `tflint` — module-level linting
4. `tfsec` + `checkov` — security policy scanning
5. `terraform plan` on the complete example (dry run, no deploy)

---

## License

MIT — see [LICENSE](LICENSE).
{
  "name": "DevOps Dev Container",
  "image": "mcr.microsoft.com/devcontainers/python:3.12",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/terraform:1": {},
    "ghcr.io/devcontainers/features/node:1": {"version": "20"}
  },
  "postCreateCommand": "pip install -r requirements.txt 2>/dev/null || true && npm ci 2>/dev/null || true",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "hashicorp.terraform",
        "ms-azuretools.vscode-docker",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
version: 2
updates:
  - package-ecosystem: pip
    directory: "/"
    schedule:
      interval: weekly
    open-pull-requests-limit: 5

  - package-ecosystem: npm
    directory: "/"
    schedule:
      interval: weekly
    open-pull-requests-limit: 5

  - package-ecosystem: docker
    directory: "/"
    schedule:
      interval: weekly

  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: weekly
* @donny-devops
/app/ @donny-devops
/.github/ @donny-devops
