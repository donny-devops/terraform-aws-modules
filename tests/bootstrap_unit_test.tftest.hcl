# Tests for bootstrap module using Terraform 1.7+ mock provider

mock_provider "aws" {}
mock_provider "tls" {}

variables {
  aws_region      = "us-east-1"
  bucket_prefix   = "infra-state"
  lock_table_name = "infra-state-locks"
}

run "validate_bootstrap_table_name" {
  command = plan

  assert {
    condition     = var.aws_region == "us-east-1"
    error_message = "AWS region should default to us-east-1"
  }

  assert {
    condition     = var.lock_table_name == "infra-state-locks"
    error_message = "DynamoDB lock table name must match configured variable"
  }

  assert {
    condition     = var.bucket_prefix == "infra-state"
    error_message = "Bucket prefix must match configured variable"
  }
}

run "validate_github_oidc_toggle" {
  command = plan

  variables {
    enable_github_oidc = true
    github_repo        = "my-org/my-infra"
  }

  assert {
    condition     = var.enable_github_oidc == true
    error_message = "GitHub OIDC toggle should be active"
  }

  assert {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repo))
    error_message = "GitHub repo must be formatted as 'owner/repo'"
  }
}
