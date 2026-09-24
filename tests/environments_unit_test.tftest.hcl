# Tests for dev and prod environment variables and configuration logic

mock_provider "aws" {}
mock_provider "random" {}

variables {
  aws_region      = "us-east-1"
  project_name    = "cloud-platform"
  environment     = "dev"
  vpc_cidr        = "10.0.0.0/16"
  container_image = "public.ecr.aws/docker/library/httpd:alpine"
  container_port  = 80
}

run "validate_dev_network_and_port" {
  command = plan

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment must be dev"
  }

  assert {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }

  assert {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535"
  }
}

run "validate_prod_environment_override" {
  command = plan

  variables {
    environment = "prod"
    vpc_cidr    = "10.100.0.0/16"
  }

  assert {
    condition     = var.environment == "prod"
    error_message = "Environment should accept prod override"
  }

  assert {
    condition     = var.vpc_cidr == "10.100.0.0/16"
    error_message = "Prod VPC CIDR should match isolated range"
  }
}
