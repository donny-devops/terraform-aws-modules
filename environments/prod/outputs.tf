output "alb_dns_name" {
  description = "Public URL / DNS name of the Application Load Balancer."
  value       = module.alb.dns_name
}

output "vpc_id" {
  description = "VPC ID where the infrastructure is deployed."
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs."
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs for app placement."
  value       = module.vpc.private_subnets
}

output "database_endpoint" {
  description = "RDS connection endpoint."
  value       = module.rds.db_instance_endpoint
}

output "database_secrets_manager_arn" {
  description = "Secrets Manager secret ARN containing generated master database credentials."
  value       = module.rds.db_instance_master_user_secret_arn
}

output "s3_bucket_name" {
  description = "Name of the asset storage S3 bucket."
  value       = module.s3_bucket.s3_bucket_id
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name."
  value       = module.container_app.cluster_name
}
