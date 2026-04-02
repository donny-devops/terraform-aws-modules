output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Elastic IPs of NAT Gateways."
  value       = module.vpc.nat_gateway_public_ips
}

output "api_endpoint" {
  description = "API Gateway invoke URL."
  value       = module.serverless_api.api_endpoint
}

output "lambda_function_names" {
  description = "Lambda function names."
  value       = module.serverless_api.lambda_function_names
}

output "dynamodb_table_names" {
  description = "DynamoDB table names."
  value       = module.serverless_api.dynamodb_table_names
}

output "website_url" {
  description = "Public website URL."
  value       = module.static_website.website_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (use this for cache invalidation)."
  value       = module.static_website.cloudfront_distribution_id
}

output "website_bucket_name" {
  description = "S3 bucket name (deploy built assets here)."
  value       = module.static_website.bucket_name
}
