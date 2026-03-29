variable "name" {
  description = "Name prefix for RDS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the RDS instance"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group (min 2 AZs)"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to RDS (e.g. ECS task SG)"
  type        = list(string)
  default     = []
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.2"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling (0 disables autoscaling)"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Name of the initial database"
  type        = string
}

variable "master_username" {
  description = "Master database username"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Master database password — store in AWS Secrets Manager in production"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0 disables)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window"
  type        = string
  default     = "Sun:04:00-Sun:05:00"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
