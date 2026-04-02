variable "name" {
  description = "Name prefix applied to all resources."
  type        = string
}

# ── S3 ────────────────────────────────────────────────────────────────────────

variable "bucket_name" {
  description = "Globally-unique S3 bucket name for website assets."
  type        = string
}

variable "index_document" {
  description = "Website index document."
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Website error document (served on 4xx from origin)."
  type        = string
  default     = "index.html"
}

# ── CloudFront ────────────────────────────────────────────────────────────────

variable "price_class" {
  description = "CloudFront price class. PriceClass_100 = US/EU only (cheapest)."
  type        = string
  default     = "PriceClass_100"
}

variable "default_ttl" {
  description = "Default TTL in seconds for cached objects."
  type        = number
  default     = 86400
}

variable "max_ttl" {
  description = "Maximum TTL in seconds for cached objects."
  type        = number
  default     = 31536000
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

# ── Route53 / ACM ─────────────────────────────────────────────────────────────

variable "domain_name" {
  description = "Primary domain name (e.g. example.com). Leave null to skip Route53/ACM."
  type        = string
  default     = null
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
