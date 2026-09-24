variable "name" {
  description = "Name identifier for the ECS cluster, service, and task definition."
  type        = string
  nullable    = false
}

variable "vpc_id" {
  description = "The ID of the VPC where the ECS service will run."
  type        = string
  nullable    = false
}

variable "subnet_ids" {
  description = "List of private subnet IDs for placing ECS Fargate tasks."
  type        = list(string)
  nullable    = false
}

variable "container_image" {
  description = "Docker image repository and tag to deploy (e.g., public.ecr.aws/docker/library/httpd:alpine or custom ECR image)."
  type        = string
  default     = "public.ecr.aws/docker/library/httpd:alpine"
  nullable    = false
}

variable "container_port" {
  description = "Port exposed by the container and targeted by the load balancer."
  type        = number
  default     = 80
  nullable    = false
}

variable "cpu" {
  description = "CPU units allocated to the Fargate task (256 = 0.25 vCPU, 512 = 0.5 vCPU, 1024 = 1 vCPU)."
  type        = number
  default     = 256
  nullable    = false
}

variable "memory" {
  description = "Memory (in MiB) allocated to the Fargate task (512, 1024, 2048, etc.)."
  type        = number
  default     = 512
  nullable    = false
}

variable "desired_count" {
  description = "Initial number of container task replicas."
  type        = number
  default     = 2
  nullable    = false
}

variable "min_capacity" {
  description = "Minimum number of tasks for autoscaling."
  type        = number
  default     = 1
  nullable    = false
}

variable "max_capacity" {
  description = "Maximum number of tasks for autoscaling."
  type        = number
  default     = 10
  nullable    = false
}

variable "target_group_arn" {
  description = "The ARN of the ALB target group to register Fargate tasks into."
  type        = string
  nullable    = false
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
