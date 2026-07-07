# Copilot Code Review Instructions — Terraform AWS Modules

## Infrastructure Security & Best Practices

### 1. Security Posture (CRITICAL)
- **IAM & Access Control**
  - Verify least-privilege IAM policies (no `*` actions or resources)
  - Check for overly permissive security group rules (0.0.0.0/0)
  - Flag missing `kms_key_id` on encrypted resources
  - Ensure S3 buckets block public access unless explicitly required
- **Secrets Management**
  - No hardcoded credentials, API keys, or tokens
  - Sensitive values must use `sensitive = true` attribute
  - Check for secrets in Terraform state (use AWS Secrets Manager)
  - Verify KMS keys for encryption at rest
- **Network Security**
  - VPC subnets should separate public/private/isolated tiers
  - NACLs and security groups follow defense-in-depth
  - Flag missing VPC flow logs
  - Check for exposed RDS/Redis endpoints

### 2. Terraform Module Standards
- **Module Structure**
  - All modules must have: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
  - `README.md` with usage examples and input/output documentation
  - `examples/` directory with working sample configurations
- **Variable Validation**
  - Use `validation` blocks for critical inputs
  - Provide clear `description` for all variables
  - Set sensible defaults where applicable
  - Mark sensitive variables: `sensitive = true`
- **Outputs**
  - Export all useful resource attributes
  - Mark sensitive outputs: `sensitive = true`
  - Use clear, consistent naming

### 3. State Management & Backend
- Check for remote backend configuration (S3 + DynamoDB locking)
- Verify state encryption is enabled
- Flag missing `prevent_destroy` on critical resources
- Check for proper workspace usage

### 4. Resource Tagging & Naming
- All resources should have consistent tags:
  - `Name`, `Environment`, `ManagedBy = "Terraform"`, `Owner`, `CostCenter`
- Use `terraform.workspace` or variables for environment-specific naming
- Avoid hardcoded resource names (use `name_prefix` or interpolation)

### 5. Cost & Performance Optimization
- Flag oversized instance types (t3.small for dev, not m5.2xlarge)
- Check for missing autoscaling configurations
- Verify proper use of spot/reserved instances
- Flag missing lifecycle policies on S3/ECR

### 6. High Availability & Resilience
- Multi-AZ deployments for production resources
- Check for missing health checks and monitoring
- Verify proper use of load balancers
- Flag single-instance deployments for critical services

### 7. Compliance & Governance
- **Encryption**
  - EBS volumes: `encrypted = true`
  - S3 buckets: server-side encryption enabled
  - RDS: encryption at rest and in transit
  - Secrets Manager for sensitive data
- **Logging & Monitoring**
  - CloudWatch log groups for all services
  - CloudTrail enabled for audit logging
  - S3 access logging where appropriate
  - VPC Flow Logs enabled

### 8. Terraform Best Practices
- Pin provider versions in `versions.tf`
- Use `terraform validate` and `terraform fmt` before commit
- Avoid count/for_each with complex expressions
- Use data sources instead of hardcoded values
- Module versioning: semantic versioning in git tags

## Code Quality Standards
- Use consistent formatting (`terraform fmt`)
- Prefer `for_each` over `count` for resource sets
- Use `locals` for complex expressions
- Document all modules with terraform-docs
- Include `.tflint.hcl` for static analysis

## Response Format
```
**[SEVERITY]**: IAM Security - Overly Permissive Policy

**Location**: `modules/vpc/iam.tf:12-18`
**Problem**: IAM role allows `s3:*` action on all resources
**Risk**: Excessive permissions violate least-privilege principle (HIGH severity)
**Fix**: 
\```hcl
# Before (too broad)
statement {
  actions   = ["s3:*"]
  resources = ["*"]
}

# After (least privilege)
statement {
  actions = [
    "s3:GetObject",
    "s3:PutObject"
  ]
  resources = [
    "arn:aws:s3:::${var.bucket_name}/*"
  ]
}
\```
**Reference**: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege
```

Severity: CRITICAL | HIGH | MEDIUM | LOW | ADVISORY
