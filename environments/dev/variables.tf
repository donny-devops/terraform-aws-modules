variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
  nullable    = false
}

variable "project_name" {
  description = "Project name prefix used for resource naming."
  type        = string
  default     = "cloud-app"
  nullable    = false
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
  nullable    = false
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false
}

variable "container_image" {
  description = "Container image for the ECS Fargate service."
  type        = string
  default     = "public.ecr.aws/docker/library/httpd:alpine"
  nullable    = false
}

variable "container_port" {
  description = "Port exposed by the container application."
  type        = number
  default     = 80
  nullable    = false
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
