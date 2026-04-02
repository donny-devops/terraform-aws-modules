variable "name" {
  description = "Name prefix applied to all resources."
  type        = string
}

# ── API Gateway ───────────────────────────────────────────────────────────────

variable "api_type" {
  description = "REST or HTTP API Gateway. Valid values: REST | HTTP."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["REST", "HTTP"], var.api_type)
    error_message = "api_type must be REST or HTTP."
  }
}

variable "api_stage_name" {
  description = "Stage name for the API Gateway deployment."
  type        = string
  default     = "v1"
}

variable "cors_allow_origins" {
  description = "CORS allowed origins (HTTP API only)."
  type        = list(string)
  default     = ["*"]
}

# ── Lambda ────────────────────────────────────────────────────────────────────

variable "lambda_functions" {
  description = <<-EOT
    Map of Lambda functions to create. Each key becomes the function name suffix.
    Attributes:
      handler      - module.function reference (e.g. "index.handler")
      runtime      - Lambda runtime (e.g. "python3.12")
      source_dir   - path to the directory containing source code (zipped automatically)
      memory_mb    - allocated memory in MB (default 128)
      timeout_sec  - function timeout in seconds (default 30)
      environment  - map of environment variables
      http_route   - HTTP API route expression, e.g. "GET /items" (optional)
  EOT
  type = map(object({
    handler     = string
    runtime     = string
    source_dir  = string
    memory_mb   = optional(number, 128)
    timeout_sec = optional(number, 30)
    environment = optional(map(string), {})
    http_route  = optional(string, null)
  }))
}

variable "lambda_vpc_config" {
  description = "Place Lambdas inside a VPC. Leave null to run outside a VPC."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# ── DynamoDB ──────────────────────────────────────────────────────────────────

variable "dynamodb_tables" {
  description = <<-EOT
    Map of DynamoDB tables to create.
    Attributes:
      hash_key     - partition key name
      hash_type    - S | N | B
      range_key    - sort key name (optional)
      range_type   - S | N | B (required when range_key is set)
      billing_mode - PAY_PER_REQUEST | PROVISIONED (default PAY_PER_REQUEST)
      read_capacity  - required when billing_mode = PROVISIONED
      write_capacity - required when billing_mode = PROVISIONED
      ttl_attribute  - attribute name used for TTL (optional)
      gsis           - list of GSI definitions (optional)
  EOT
  type = map(object({
    hash_key       = string
    hash_type      = string
    range_key      = optional(string, null)
    range_type     = optional(string, null)
    billing_mode   = optional(string, "PAY_PER_REQUEST")
    read_capacity  = optional(number, null)
    write_capacity = optional(number, null)
    ttl_attribute  = optional(string, null)
    gsis = optional(list(object({
      name            = string
      hash_key        = string
      hash_type       = string
      range_key       = optional(string, null)
      range_type      = optional(string, null)
      projection_type = optional(string, "ALL")
      read_capacity   = optional(number, null)
      write_capacity  = optional(number, null)
    })), [])
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
