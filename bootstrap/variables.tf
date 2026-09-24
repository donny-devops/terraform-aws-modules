variable "aws_region" {
  description = "The AWS region where state storage and locking resources will be provisioned."
  type        = string
  default     = "us-east-1"
  nullable    = false
}

variable "bucket_prefix" {
  description = "Prefix used for the S3 state bucket and DynamoDB table name."
  type        = string
  default     = "terraform-state"
  nullable    = false
}

variable "lock_table_name" {
  description = "Custom name for the DynamoDB state lock table. If left null, a name is generated using bucket_prefix and random suffix."
  type        = string
  default     = null
}

variable "enable_github_oidc" {
  description = "Whether to create the AWS IAM OIDC Provider and Role for GitHub Actions CI/CD."
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' permitted to assume the deployment role."
  type        = string
  default     = "donny-devops/terraform-aws-modules"
}

variable "tags" {
  description = "Additional tags to apply to all bootstrap resources."
  type        = map(string)
  default     = {}
}
