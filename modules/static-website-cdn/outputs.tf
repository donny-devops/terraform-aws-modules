output "bucket_name" {
  description = "Name of the S3 website bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 website bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket (used for CloudFront origin)."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.this.arn
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution (e.g. d1234abcdef.cloudfront.net)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution (for Route53 alias records)."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "website_url" {
  description = "Public website URL (uses custom domain when configured, otherwise CloudFront domain)."
  value = (
    var.domain_name != null
    ? "https://${var.domain_name}"
    : "https://${aws_cloudfront_distribution.this.domain_name}"
  )
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1 (null when no custom domain)."
  value       = try(aws_acm_certificate.this[0].arn, var.acm_certificate_arn)
}
