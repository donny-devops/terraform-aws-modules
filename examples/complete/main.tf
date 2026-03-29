terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "complete-example/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "donny-devops-complete"
      Environment = "example"
      ManagedBy   = "terraform"
    }
  }
}

# ── VPC ────────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "../../modules/vpc"

  name    = "donny-complete"
  vpc_cidr = "10.0.0.0/16"
  azs     = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway       = true
  single_nat_gateway       = false
  enable_flow_logs         = true
  flow_logs_retention_days = 30
}

# ── RDS ────────────────────────────────────────────────────────────────────────

module "rds" {
  source = "../../modules/rds"

  name       = "donny-complete-db"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.ecs.security_group_id]

  database_name   = "appdb"
  master_username = "appuser"
  master_password = var.db_password

  instance_class        = "db.t3.small"
  allocated_storage     = 20
  max_allocated_storage = 100
  multi_az              = false
  deletion_protection   = false
}

# ── ECS ────────────────────────────────────────────────────────────────────────

module "ecs" {
  source = "../../modules/ecs"

  name           = "donny-complete-api"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  container_image = "ghcr.io/donny-devops/docker-flask-postgres-api:latest"
  container_port  = 5000

  cpu           = 256
  memory        = 512
  desired_count = 2

  environment_variables = {
    FLASK_ENV  = "production"
  }

  secrets = {
    DATABASE_URL = aws_ssm_parameter.db_url.arn
    SECRET_KEY   = aws_ssm_parameter.secret_key.arn
  }

  enable_autoscaling       = true
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 10
}

# ── SSM Parameters ─────────────────────────────────────────────────────────────

resource "aws_ssm_parameter" "db_url" {
  name  = "/donny-complete/DATABASE_URL"
  type  = "SecureString"
  value = "postgresql://${module.rds.db_host}:${module.rds.db_port}/${module.rds.db_name}"
}

resource "aws_ssm_parameter" "secret_key" {
  name  = "/donny-complete/SECRET_KEY"
  type  = "SecureString"
  value = var.flask_secret_key
}

# ── Variables ──────────────────────────────────────────────────────────────────

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "flask_secret_key" {
  description = "Flask SECRET_KEY"
  type        = string
  sensitive   = true
}

# ── Outputs ────────────────────────────────────────────────────────────────────

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "db_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}
