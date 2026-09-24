terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # NOTE: To use remote state, run 'bootstrap/bootstrap-backend.ps1' or uncomment
  # and populate the block below after running the bootstrap module:
  #
  # backend "s3" {
  #   bucket         = "tf-state-xxxx"
  #   key            = "platform/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "tf-state-locks-xxxx"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Environment = var.environment
        Project     = var.project_name
        ManagedBy   = "Terraform"
      },
      var.tags
    )
  }
}
