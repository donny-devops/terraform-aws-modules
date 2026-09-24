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
# 1. NETWORKING: Production Multi-AZ VPC with Dedicated NAT per AZ & Flow Logs
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

  # High Availability: 1 NAT Gateway per AZ
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Security & Compliance: VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. SECURITY GROUPS
# ─────────────────────────────────────────────────────────────────────────────

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name        = "${local.name}-alb-sg"
  description = "Security group for public production ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_rules = ["all-all"]
}

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1"

  name        = "${local.name}-db-sg"
  description = "Security group for production database tier"
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
# 3. LOAD BALANCER: Public ALB with HTTPS and HTTP-to-HTTPS Redirection
# ─────────────────────────────────────────────────────────────────────────────

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.9"

  name    = "${local.name}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  security_groups = [module.alb_sg.security_group_id]

  drop_invalid_header_fields = true

  listeners = {
    # Port 80 Redirects to Port 443
    http_redirect = {
      port     = 80
      protocol = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    # Port 443 HTTPS Traffic
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn

      forward = {
        target_group_key = "ecs_prod_app"
      }
    }
  }

  target_groups = {
    ecs_prod_app = {
      name_prefix      = "papp-"
      protocol         = "HTTP"
      port             = var.container_port
      target_type      = "ip" # Required for Fargate awsvpc
      backend_protocol = "HTTP"

      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/health"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 20
        matcher             = "200"
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. COMPUTE: High-Availability ECS Fargate Service
# ─────────────────────────────────────────────────────────────────────────────

module "container_app" {
  source = "../../modules/container-service"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  container_image    = var.container_image
  container_port     = var.container_port
  cpu                = 1024 # 1 vCPU
  memory             = 2048 # 2 GB
  desired_count      = 4
  min_capacity       = 2
  max_capacity       = 20
  target_group_arn   = module.alb.target_groups["ecs_prod_app"].arn
  enable_autoscaling = true

  environment_variables = {
    ENVIRONMENT = var.environment
    DB_HOST     = module.rds.db_instance_address
    DB_NAME     = "appdb_prod"
    S3_BUCKET   = module.s3_bucket.s3_bucket_id
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. DATABASE: Production Multi-AZ PostgreSQL RDS
# ─────────────────────────────────────────────────────────────────────────────

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.5"

  identifier = "${local.name}-postgres"

  engine               = "postgres"
  engine_version       = "16.1"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.r6g.large"

  allocated_storage     = 100
  max_allocated_storage = 500

  db_name  = "appdb_prod"
  username = "dbadmin_prod"
  port     = 5432

  manage_master_user_password = true

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_sg.security_group_id]

  # Production High Availability and Durability
  multi_az                      = true
  deletion_protection           = true
  skip_final_snapshot           = false
  final_snapshot_identifier     = "${local.name}-final-snapshot"
  backup_retention_period       = 30
  performance_insights_enabled  = true
  auto_minor_version_upgrade    = true
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. STORAGE: Hardened S3 Bucket with Lifecycle Tiering
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

  lifecycle_rule = [
    {
      id      = "archive-prod-assets"
      enabled = true

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]
}
