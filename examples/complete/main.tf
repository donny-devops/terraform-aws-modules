terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Uncomment and configure for remote state:
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"
  #   key            = "complete-example/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

# CloudFront requires ACM certificates in us-east-1 regardless of the main region.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  name = "${var.project_name}-${var.environment}"
}

# ── 1. VPC / Networking ───────────────────────────────────────────────────────

module "vpc" {
  source = "../../modules/vpc"

  name = local.name
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnet_cidrs  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnet_cidrs = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  enable_nat_gateway = true
  single_nat_gateway = var.environment != "production"

  tags = { Environment = var.environment }
}

# ── 2. Serverless API ─────────────────────────────────────────────────────────

module "serverless_api" {
  source = "../../modules/serverless-api"

  name           = local.name
  api_type       = "HTTP"
  api_stage_name = "v1"

  cors_allow_origins = ["https://${var.domain_name}"]

  lambda_functions = {
    items = {
      handler    = "index.handler"
      runtime    = "python3.12"
      source_dir = "${path.module}/lambda/items"
      memory_mb  = 256
      http_route = "ANY /items/{proxy+}"
      environment = {
        LOG_LEVEL = "INFO"
      }
    }
    auth = {
      handler    = "index.handler"
      runtime    = "python3.12"
      source_dir = "${path.module}/lambda/auth"
      memory_mb  = 128
      http_route = "POST /auth/{proxy+}"
    }
  }

  dynamodb_tables = {
    items = {
      hash_key  = "PK"
      hash_type = "S"
      range_key = "SK"
      range_type = "S"
      ttl_attribute = "ExpiresAt"
      gsis = [
        {
          name            = "GSI1"
          hash_key        = "GSI1PK"
          hash_type       = "S"
          range_key       = "GSI1SK"
          range_type      = "S"
          projection_type = "ALL"
        }
      ]
    }
  }

  lambda_vpc_config = {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = { Environment = var.environment }
}

resource "aws_security_group" "lambda" {
  name        = "${local.name}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-lambda-sg" }
}

# ── 3. Static Website + CDN ───────────────────────────────────────────────────

module "static_website" {
  source = "../../modules/static-website-cdn"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name        = local.name
  bucket_name = "${local.name}-website-${random_id.suffix.hex}"

  domain_name    = var.domain_name
  aliases        = ["www.${var.domain_name}"]
  hosted_zone_id = var.hosted_zone_id

  price_class = var.environment == "production" ? "PriceClass_All" : "PriceClass_100"

  custom_error_responses = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
      ttl                = 300
    },
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
      ttl                = 300
    }
  ]

  tags = { Environment = var.environment }
}

resource "random_id" "suffix" {
  byte_length = 4
}
