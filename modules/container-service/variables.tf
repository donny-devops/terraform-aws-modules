variable "name" {
  description = "Name identifier for the ECS cluster, service, and task definition."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.name)) > 0 && length(var.name) <= 64
    error_message = "name must be 1-64 characters."
  }
}

variable "vpc_id" {
  description = "The ID of the VPC where the ECS service will run."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "subnet_ids" {
  description = "List of private subnet IDs for placing ECS Fargate tasks."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet."
  }
}

variable "container_image" {
  description = "Docker image repository and tag to deploy (e.g., public.ecr.aws/docker/library/httpd:alpine or custom ECR image)."
  type        = string
  default     = "public.ecr.aws/docker/library/httpd:alpine"
  nullable    = false

  validation {
    condition     = length(trimspace(var.container_image)) > 0
    error_message = "container_image must not be empty."
  }
}

variable "container_port" {
  description = "Port exposed by the container and targeted by the load balancer."
  type        = number
  default     = 80
  nullable    = false

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "cpu" {
  description = "CPU units allocated to the Fargate task (256 = 0.25 vCPU, 512 = 0.5 vCPU, 1024 = 1 vCPU)."
  type        = number
  default     = 256
  nullable    = false

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.cpu)
    error_message = "cpu must be a supported Fargate value: 256, 512, 1024, 2048, 4096, 8192, or 16384."
  }
}

variable "memory" {
  description = "Memory (in MiB) allocated to the Fargate task (512, 1024, 2048, etc.)."
  type        = number
  default     = 512
  nullable    = false

  validation {
    condition = (
      (var.cpu == 256 && contains([512, 1024, 2048], var.memory)) ||
      (var.cpu == 512 && contains([1024, 2048, 3072, 4096], var.memory)) ||
      (var.cpu == 1024 && var.memory >= 2048 && var.memory <= 8192 && var.memory % 1024 == 0) ||
      (var.cpu == 2048 && var.memory >= 4096 && var.memory <= 16384 && var.memory % 1024 == 0) ||
      (var.cpu == 4096 && var.memory >= 8192 && var.memory <= 30720 && var.memory % 1024 == 0) ||
      (var.cpu == 8192 && var.memory >= 16384 && var.memory <= 61440 && var.memory % 4096 == 0) ||
      (var.cpu == 16384 && var.memory >= 32768 && var.memory <= 122880 && var.memory % 8192 == 0)
    )
    error_message = "memory is not a valid Fargate size for the selected cpu."
  }
}

variable "desired_count" {
  description = "Initial number of container task replicas."
  type        = number
  default     = 2
  nullable    = false

  validation {
    condition     = var.desired_count >= 0 && var.desired_count <= var.max_capacity
    error_message = "desired_count must be between 0 and max_capacity."
  }
}

variable "min_capacity" {
  description = "Minimum number of tasks for autoscaling."
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = var.min_capacity >= 0 && var.min_capacity <= var.max_capacity
    error_message = "min_capacity must be between 0 and max_capacity."
  }
}

variable "max_capacity" {
  description = "Maximum number of tasks for autoscaling."
  type        = number
  default     = 10
  nullable    = false

  validation {
    condition     = var.max_capacity >= 1 && var.max_capacity <= 100
    error_message = "max_capacity must be between 1 and 100."
  }
}

variable "target_group_arn" {
  description = "The ARN of the ALB target group to register Fargate tasks into."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.target_group_arn)) > 0
    error_message = "target_group_arn must not be empty."
  }
}

variable "security_group_ids" {
  description = "Security group IDs to associate with the ECS task ENIs."
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Key-value map of environment variables passed to the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "List of secrets to inject from AWS SSM Parameter Store or Secrets Manager (name and valueFrom ARN)."
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "enable_autoscaling" {
  description = "Whether to attach autoscaling policies based on CPU and memory utilization."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
