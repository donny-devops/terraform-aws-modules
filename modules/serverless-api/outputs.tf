output "lambda_function_arns" {
  description = "Map of function key → Lambda ARN."
  value       = { for k, f in aws_lambda_function.this : k => f.arn }
}

output "lambda_function_names" {
  description = "Map of function key → Lambda function name."
  value       = { for k, f in aws_lambda_function.this : k => f.function_name }
}

output "lambda_role_arn" {
  description = "ARN of the shared Lambda execution IAM role."
  value       = aws_iam_role.lambda_exec.arn
}

output "dynamodb_table_names" {
  description = "Map of table key → DynamoDB table name."
  value       = { for k, t in aws_dynamodb_table.this : k => t.name }
}

output "dynamodb_table_arns" {
  description = "Map of table key → DynamoDB table ARN."
  value       = { for k, t in aws_dynamodb_table.this : k => t.arn }
}

output "api_endpoint" {
  description = "Base invoke URL for the API Gateway stage."
  value = (
    var.api_type == "HTTP"
    ? try("${aws_apigatewayv2_api.http[0].api_endpoint}/${var.api_stage_name}", null)
    : try("https://${aws_api_gateway_rest_api.rest[0].id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.api_stage_name}", null)
  )
}

output "api_id" {
  description = "ID of the API Gateway API."
  value = (
    var.api_type == "HTTP"
    ? try(aws_apigatewayv2_api.http[0].id, null)
    : try(aws_api_gateway_rest_api.rest[0].id, null)
  )
}

data "aws_region" "current" {}
