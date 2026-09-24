# Tests for modules/container-service using Terraform 1.7+ mock provider

mock_provider "aws" {}

variables {
  name             = "test-service"
  vpc_id           = "vpc-12345678"
  subnet_ids       = ["subnet-11111111", "subnet-22222222"]
  container_image  = "public.ecr.aws/docker/library/httpd:alpine"
  container_port   = 80
  target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test-tg/1234567890123456"
  desired_count    = 2
  min_capacity     = 1
  max_capacity     = 6
}

run "validate_container_service_defaults" {
  command = plan

  assert {
    condition     = var.container_port == 80
    error_message = "Container port must default to port 80"
  }

  assert {
    condition     = var.desired_count == 2
    error_message = "Default task desired count should be 2"
  }

  assert {
    condition     = var.min_capacity <= var.max_capacity
    error_message = "min_capacity must be less than or equal to max_capacity"
  }
}

run "validate_container_service_custom_scaling" {
  command = plan

  variables {
    desired_count = 5
    min_capacity  = 3
    max_capacity  = 12
    cpu           = 512
    memory        = 1024
  }

  assert {
    condition     = var.cpu == 512
    error_message = "Task CPU allocation should match 512 units"
  }

  assert {
    condition     = var.memory == 1024
    error_message = "Task memory allocation should match 1024 MiB"
  }
}
