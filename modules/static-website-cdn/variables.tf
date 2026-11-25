variable "name" {
  description = "Name prefix applied to all resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must be a non-empty string."
  }
}

# ── S3 ──────────────────────────────────────────────────────────────────────

variable "bucket_name" {
  description = "Globally-unique S3 bucket name for website assets."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, lowercase letters, numbers, dots, or hyphens."
  }
}

variable "index_document" {
  description = "Website index document."
  type        = string
  default     = "index.html"

  validation {
    condition     = length(trimspace(var.index_document)) > 0
    error_message = "index_document must not be empty."
  }
}

variable "error_document" {
  description = "Website error document (served on 4xx from origin)."
  type        = string
  default     = "index.html"

  validation {
    condition     = length(trimspace(var.error_document)) > 0
    error_message = "error_document must not be empty."
  }
}

# ── CloudFront ──────────────────────────────────────────────────────────────

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = US/EU only (cheapest)."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "default_ttl" {
  description = "Default TTL in seconds for cached objects."
  type        = number
  default     = 86400

  validation {
    condition     = var.default_ttl >= 0 && var.default_ttl <= var.max_ttl
    error_message = "default_ttl must be between 0 and max_ttl."
  }
}

variable "max_ttl" {
  description = "Maximum TTL in seconds for cached objects."
  type        = number
  default     = 31536000

  validation {
    condition     = var.max_ttl >= 0
    error_message = "max_ttl must be zero or greater."
  }
}

variable "compress" {
  description = "Automatically compress objects for supported content types."
  type        = bool
  default     = true
}

variable "web_acl_id" {
  description = "ARN of an AWS WAFv2 WebACL to associate with the distribution (optional)."
  type        = string
  default     = null
}

variable "custom_error_responses" {
  description = <<-EOT
    List of custom error response configurations (useful for SPA routing).
    Each object: { error_code, response_code, response_page_path, ttl }
  EOT
  type = list(object({
    error_code         = number
    response_code      = number
    response_page_path = string
    ttl                = optional(number, 300)
  }))
  default = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
      ttl                = 300
    },
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
      ttl                = 300
    }
  ]
}

# ── Route53 / ACM ────────────────────────────────────────────────────────────

variable "domain_name" {
  description = "Primary domain name (e.g. example.com). Leave null to skip Route53/ACM."
  type        = string
  default     = null

  validation {
    condition     = var.domain_name == null || (var.hosted_zone_id != null && length(var.hosted_zone_id) > 0)
    error_message = "hosted_zone_id is required when domain_name is set."
  }
}

variable "aliases" {
  description = "Additional CloudFront aliases (e.g. [\"www.example.com\"])."
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID for the domain. Required when domain_name is set."
  type        = string
  default     = null
}

variable "create_acm_certificate" {
  description = "Create and validate an ACM certificate for the domain. Requires hosted_zone_id."
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "ARN of an existing ACM certificate (us-east-1). Overrides create_acm_certificate."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
