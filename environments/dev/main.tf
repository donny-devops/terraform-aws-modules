data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. NETWORKING: Multi-AZ VPC using terraform-aws-modules/vpc/aws
# ─────────────────────────────────────────────────────────────────────────────

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 10)]
  database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 20)]

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  # Cost optimization for dev: Single NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. SECURITY GROUPS: Layered Rules using terraform-aws-modules/security-group/aws
# ─────────────────────────────────────────────────────────────────────────────

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name        = "${local.name}-alb-sg"
  description = "Security group for public ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]

  egress_rules = ["all-all"]
}

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name        = "${local.name}-db-sg"
  description = "Security group for database tier"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "postgresql-tcp"
      cidr_blocks = var.vpc_cidr
    }
  ]

  egress_rules = ["all-all"]
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. LOAD BALANCER: Public ALB using terraform-aws-modules/alb/aws
# ─────────────────────────────────────────────────────────────────────────────

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.9"

  name    = "${local.name}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  security_groups = [module.alb_sg.security_group_id]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ecs_app"
      }
    }
  }

  target_groups = {
    ecs_app = {
      name_prefix      = "app-"
      protocol         = "HTTP"
      port             = var.container_port
      target_type      = "ip" # Required for Fargate awsvpc networking
      backend_protocol = "HTTP"

      # Attachments are registered dynamically by ECS
      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        matcher             = "200"
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. COMPUTE: Containerized Application using custom module + terraform-aws-modules/ecs
# ─────────────────────────────────────────────────────────────────────────────

module "container_app" {
  source = "../../modules/container-service"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  container_image    = var.container_image
  container_port     = var.container_port
  desired_count      = 2
  min_capacity       = 1
  max_capacity       = 4
  target_group_arn   = module.alb.target_groups["ecs_app"].arn
  enable_autoscaling = true

  environment_variables = {
    ENVIRONMENT = var.environment
    DB_HOST     = module.rds.db_instance_address
    DB_NAME     = "appdb"
    S3_BUCKET   = module.s3_bucket.s3_bucket_id
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. DATABASE: PostgreSQL RDS using terraform-aws-modules/rds/aws
# ─────────────────────────────────────────────────────────────────────────────

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.5"

  identifier = "${local.name}-postgres"

  engine               = "postgres"
  engine_version       = "16.1"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 50

  db_name  = "appdb"
  username = "dbadmin"
  port     = 5432

  # Generates and stores credentials in AWS Secrets Manager
  manage_master_user_password = true

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_sg.security_group_id]

  # Dev settings: single-AZ and fast tear-down
  multi_az            = false
  skip_final_snapshot = true
  deletion_protection = false
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. STORAGE: S3 Asset Bucket using terraform-aws-modules/s3-bucket/aws
# ─────────────────────────────────────────────────────────────────────────────

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket = "${local.name}-assets-${random_id.suffix.hex}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    status = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}
