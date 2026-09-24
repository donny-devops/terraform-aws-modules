variable "name" {
  description = "Base resource name prefix"
  type        = string
}

variable "scope" {
  description = "WAF scope: REGIONAL or CLOUDFRONT"
  type        = string
  default     = "REGIONAL"
}

variable "rate_limit" {
  description = "Requests per 5-minute window before IP is throttled"
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
