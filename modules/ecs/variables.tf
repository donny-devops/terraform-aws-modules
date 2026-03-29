variable "name" {
  description = "Name prefix for ECS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ECS service will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ECS service (private subnets recommended)"
  type        = list(string)
}

variable "container_image" {
  description = "Docker image URI for the task (e.g. ghcr.io/org/app:sha-abc123)"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU units for the Fargate task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory (MiB) for the Fargate task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of ECS task instances"
  type        = number
  default     = 2
}

variable "environment_variables" {
  description = "Environment variables to pass to the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "SSM Parameter Store ARNs to inject as environment variables"
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  description = "Whether to enable Application Auto Scaling for the ECS service"
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks when autoscaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks when autoscaling"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
