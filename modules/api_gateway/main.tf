###############################################################################
# REST API Gateway with native API Key authentication
###############################################################################
resource "aws_api_gateway_rest_api" "this" {
  name = "${var.project_name}-${var.environment}-api"
}

# ── Resources (paths) ───────────────────────────────────────────────────────
resource "aws_api_gateway_resource" "templates" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "templates"
}

resource "aws_api_gateway_resource" "modify" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "modify"
}

resource "aws_api_gateway_resource" "download" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "download"
}

resource "aws_api_gateway_resource" "preview" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "preview"
}

# ── Methods (API key required) ──────────────────────────────────────────────
resource "aws_api_gateway_method" "get_templates" {
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.templates.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "post_modify" {
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.modify.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "get_download" {
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.download.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "get_preview" {
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.preview.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_method" "head_preview" {
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.preview.id
  http_method      = "HEAD"
  authorization    = "NONE"
  api_key_required = false
}

# ── Lambda Proxy Integrations ──────────────────────────────────────────────
resource "aws_api_gateway_integration" "get_templates" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.templates.id
  http_method             = aws_api_gateway_method.get_templates.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_integration" "post_modify" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.modify.id
  http_method             = aws_api_gateway_method.post_modify.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_integration" "get_download" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.download.id
  http_method             = aws_api_gateway_method.get_download.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_integration" "get_preview" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.preview.id
  http_method             = aws_api_gateway_method.get_preview.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_integration" "head_preview" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.preview.id
  http_method             = aws_api_gateway_method.head_preview.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

# ── CORS (OPTIONS methods) ─────────────────────────────────────────────────
locals {
  cors_resources = {
    templates = aws_api_gateway_resource.templates.id
    modify    = aws_api_gateway_resource.modify.id
    download  = aws_api_gateway_resource.download.id
    preview   = aws_api_gateway_resource.preview.id
  }
}

resource "aws_api_gateway_method" "options" {
  for_each      = local.cors_resources
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS,HEAD'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origins[0]}'"
  }
}

# ── Deployment + Stage ─────────────────────────────────────────────────────
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.templates,
      aws_api_gateway_resource.modify,
      aws_api_gateway_resource.download,
      aws_api_gateway_resource.preview,
      aws_api_gateway_method.get_templates,
      aws_api_gateway_method.post_modify,
      aws_api_gateway_method.get_download,
      aws_api_gateway_method.get_preview,
      aws_api_gateway_method.head_preview,
      aws_api_gateway_integration.get_templates,
      aws_api_gateway_integration.post_modify,
      aws_api_gateway_integration.get_download,
      aws_api_gateway_integration.get_preview,
      aws_api_gateway_integration.head_preview,
      aws_api_gateway_method.options,
      aws_api_gateway_integration.options,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.environment
}

# ── API Key + Usage Plan (pure Terraform, no Lambda) ───────────────────────
resource "aws_api_gateway_api_key" "this" {
  name    = "${var.project_name}-${var.environment}-api-key"
  enabled = true
}

resource "aws_api_gateway_usage_plan" "this" {
  name = "${var.project_name}-${var.environment}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "this" {
  key_id        = aws_api_gateway_api_key.this.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}

# ── Lambda permission ──────────────────────────────────────────────────────
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "local_file" "frontend_env" {
  count    = var.frontend_env_path != null ? 1 : 0
  filename = var.frontend_env_path
  content  = <<-EOT
    VITE_LAMBDA_URL=${aws_api_gateway_stage.this.invoke_url}
    VITE_TEMPLATES_API_KEY=${aws_api_gateway_api_key.this.value}
    VITE_TEMPLATES_API_URL="${aws_api_gateway_stage.this.invoke_url}/templates"
    VITE_MODIFY_API_URL="${aws_api_gateway_stage.this.invoke_url}/modify"
    VITE_DOWNLOAD_API_URL="${aws_api_gateway_stage.this.invoke_url}/download"
    VITE_PREVIEW_API_URL="${aws_api_gateway_stage.this.invoke_url}/preview"
  EOT
}

