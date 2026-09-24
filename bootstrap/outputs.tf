output "s3_bucket_name" {
  description = "The name of the S3 bucket configured for Terraform state storage."
  value       = aws_s3_bucket.state.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket configured for Terraform state storage."
  value       = aws_s3_bucket.state.arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table configured for Terraform state locking."
  value       = aws_dynamodb_table.locks.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table configured for Terraform state locking."
  value       = aws_dynamodb_table.locks.arn
}

output "backend_config_hcl_snippet" {
  description = "Example backend.tf block to paste into your environment roots."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.state.id}"
        key            = "<environment-name>/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.locks.name}"
        encrypt        = true
      }
    }
  EOT
}
