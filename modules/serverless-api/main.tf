locals {
  common_tags = merge(
    { Name = var.name, ManagedBy = "terraform" },
    var.tags,
  )
}

# ── Lambda Execution Role ─────────────────────────────────────────────────────

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.name}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = var.lambda_vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Inline policy granting access to all DynamoDB tables created by this module.
data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:TransactWriteItems",
      "dynamodb:TransactGetItems",
    ]
    resources = flatten([
      for k, t in aws_dynamodb_table.this : [t.arn, "${t.arn}/index/*"]
    ])
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  count  = length(var.dynamodb_tables) > 0 ? 1 : 0
  name   = "${var.name}-dynamodb-access"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

# ── Lambda Functions ──────────────────────────────────────────────────────────

data "archive_file" "lambda" {
  for_each = var.lambda_functions

  type        = "zip"
  source_dir  = each.value.source_dir
  output_path = "${path.module}/.build/${each.key}.zip"
}

resource "aws_lambda_function" "this" {
  for_each = var.lambda_functions

  function_name    = "${var.name}-${each.key}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = data.archive_file.lambda[each.key].output_path
  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256
  memory_size      = each.value.memory_mb
  timeout          = each.value.timeout_sec

  environment {
    variables = merge(
      # Inject table names automatically so Lambdas can reference them by a
      # consistent env var convention: DYNAMODB_TABLE_<UPPER_KEY>
      {
        for table_key, table in aws_dynamodb_table.this :
        "DYNAMODB_TABLE_${upper(replace(table_key, "-", "_"))}" => table.name
      },
      each.value.environment,
    )
  }

  dynamic "vpc_config" {
    for_each = var.lambda_vpc_config != null ? [var.lambda_vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tags = merge(local.common_tags, { Function = each.key })
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = var.lambda_functions

  name              = "/aws/lambda/${var.name}-${each.key}"
  retention_in_days = 14

  tags = local.common_tags
}

# ── DynamoDB Tables ───────────────────────────────────────────────────────────

resource "aws_dynamodb_table" "this" {
  for_each = var.dynamodb_tables

  name         = "${var.name}-${each.key}"
  billing_mode = each.value.billing_mode
  hash_key     = each.value.hash_key

  read_capacity  = each.value.billing_mode == "PROVISIONED" ? each.value.read_capacity : null
  write_capacity = each.value.billing_mode == "PROVISIONED" ? each.value.write_capacity : null

  range_key = each.value.range_key

  attribute {
    name = each.value.hash_key
    type = each.value.hash_type
  }

  dynamic "attribute" {
    for_each = each.value.range_key != null ? [1] : []
    content {
      name = each.value.range_key
      type = each.value.range_type
    }
  }

  # GSI hash/range keys may need additional attribute definitions.
  dynamic "attribute" {
    for_each = {
      for gsi in each.value.gsis : gsi.hash_key => gsi.hash_type
      if gsi.hash_key != each.value.hash_key && gsi.hash_key != each.value.range_key
    }
    content {
      name = attribute.key
      type = attribute.value
    }
  }

  dynamic "global_secondary_index" {
    for_each = each.value.gsis
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type
      read_capacity   = each.value.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity  = each.value.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  dynamic "ttl" {
    for_each = each.value.ttl_attribute != null ? [each.value.ttl_attribute] : []
    content {
      attribute_name = ttl.value
      enabled        = true
    }
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(local.common_tags, { Table = each.key })
}

# ── HTTP API Gateway (default) ────────────────────────────────────────────────

resource "aws_apigatewayv2_api" "http" {
  count = var.api_type == "HTTP" ? 1 : 0

  name          = "${var.name}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Api-Key"]
    max_age       = 86400
  }

  tags = local.common_tags
}

resource "aws_apigatewayv2_stage" "http" {
  count = var.api_type == "HTTP" ? 1 : 0

  api_id      = aws_apigatewayv2_api.http[0].id
  name        = var.api_stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_http[0].arn
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "api_http" {
  count             = var.api_type == "HTTP" ? 1 : 0
  name              = "/aws/apigateway/${var.name}-http"
  retention_in_days = 14
  tags              = local.common_tags
}

# HTTP integrations — one per Lambda function that declares an http_route.
locals {
  http_routed_functions = {
    for k, f in var.lambda_functions : k => f if f.http_route != null && var.api_type == "HTTP"
  }
}

resource "aws_apigatewayv2_integration" "http" {
  for_each = local.http_routed_functions

  api_id                 = aws_apigatewayv2_api.http[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.this[each.key].invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "http" {
  for_each = local.http_routed_functions

  api_id    = aws_apigatewayv2_api.http[0].id
  route_key = each.value.http_route
  target    = "integrations/${aws_apigatewayv2_integration.http[each.key].id}"
}

resource "aws_lambda_permission" "apigw_http" {
  for_each = local.http_routed_functions

  statement_id  = "AllowHTTPAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http[0].execution_arn}/*/*"
}

# ── REST API Gateway ──────────────────────────────────────────────────────────

resource "aws_api_gateway_rest_api" "rest" {
  count = var.api_type == "REST" ? 1 : 0

  name = "${var.name}-rest-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.common_tags
}

# Proxy resource — catches all paths; each Lambda handles its own routing.
resource "aws_api_gateway_resource" "proxy" {
  count = var.api_type == "REST" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.rest[0].id
  parent_id   = aws_api_gateway_rest_api.rest[0].root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_any" {
  count = var.api_type == "REST" ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.rest[0].id
  resource_id   = aws_api_gateway_resource.proxy[0].id
  http_method   = "ANY"
  authorization = "NONE"
}

# Wire first Lambda (by sorted key) as the proxy integration for REST API.
locals {
  rest_primary_function_key = var.api_type == "REST" ? tolist(sort(keys(var.lambda_functions)))[0] : null
}

resource "aws_api_gateway_integration" "proxy" {
  count = var.api_type == "REST" ? 1 : 0

  rest_api_id             = aws_api_gateway_rest_api.rest[0].id
  resource_id             = aws_api_gateway_resource.proxy[0].id
  http_method             = aws_api_gateway_method.proxy_any[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this[local.rest_primary_function_key].invoke_arn
}

resource "aws_api_gateway_deployment" "rest" {
  count = var.api_type == "REST" ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.rest[0].id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy[0].id,
      aws_api_gateway_method.proxy_any[0].id,
      aws_api_gateway_integration.proxy[0].id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "rest" {
  count = var.api_type == "REST" ? 1 : 0

  deployment_id = aws_api_gateway_deployment.rest[0].id
  rest_api_id   = aws_api_gateway_rest_api.rest[0].id
  stage_name    = var.api_stage_name

  tags = local.common_tags
}

resource "aws_lambda_permission" "apigw_rest" {
  for_each = var.api_type == "REST" ? var.lambda_functions : {}

  statement_id  = "AllowRESTAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest[0].execution_arn}/*/*"
}
