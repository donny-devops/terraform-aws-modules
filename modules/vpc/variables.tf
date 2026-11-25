variable "name" {
  description = "Name prefix applied to all resources."
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "name must be a non-empty string."
  }
}

variable "cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "cidr must be a valid IPv4 CIDR block."
  }
}

variable "azs" {
  description = "List of Availability Zones to deploy subnets into."
  type        = list(string)

  validation {
    condition     = length(var.azs) > 0
    error_message = "azs must contain at least one Availability Zone."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs length must match azs length."
  }

  validation {
    condition     = alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "All public_subnet_cidrs must be valid IPv4 CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs length must match azs length."
  }

  validation {
    condition     = alltrue([for c in var.private_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "All private_subnet_cidrs must be valid IPv4 CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateways for private subnets. Set false to save cost in dev environments."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway shared across all AZs instead of one per AZ."
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
