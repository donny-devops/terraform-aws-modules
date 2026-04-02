variable "aws_region" {
  description = "AWS region for all resources (except ACM certificates, which are always us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used as a name prefix."
  type        = string
}

variable "environment" {
  description = "Deployment environment: development | staging | production."
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "environment must be development, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Primary domain name for the website (e.g. example.com). Leave empty string to skip DNS/ACM."
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID for the domain. Required when domain_name is set."
  type        = string
  default     = null
}
