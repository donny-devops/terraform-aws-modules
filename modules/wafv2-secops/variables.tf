variable "name" {
  description = "Base resource name prefix"
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must be a non-empty string."
  }
}

variable "scope" {
  description = "WAF scope: REGIONAL or CLOUDFRONT"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "rate_limit" {
  description = "Requests per 5-minute window before IP is throttled"
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit >= 100 && var.rate_limit <= 2000000000
    error_message = "rate_limit must be between 100 and 2000000000."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
