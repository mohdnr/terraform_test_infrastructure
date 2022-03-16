resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "Flask"
  description = "API Gateway that proxies all requests to the Flask Lambda function"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id       = aws_api_gateway_rest_api.api_gateway.id
  stage_description = md5(file("api_gateway.tf")) # Force a new deployment when this file changes

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.api_proxy_integration,
  ]
}

resource "aws_api_gateway_stage" "api_stage" {
  # checkov:skip=CKV2_AWS_29:WAF not needed for non-prod use
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  stage_name    = "dev"

  cache_cluster_enabled = false
  xray_tracing_enabled  = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
    format          = "{\"requestId\":\"$context.requestId\", \"ip\": \"$context.identity.sourceIp\", \"caller\":\"$context.identity.caller\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\", \"resourcePath\":\"$context.resourcePath\", \"status\":\"$context.status\", \"responseLength\":\"$context.responseLength\"}"
  }
}

resource "aws_api_gateway_resource" "api_gateway_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "api_gateway_proxy_method" {
  rest_api_id      = aws_api_gateway_rest_api.api_gateway.id
  resource_id      = aws_api_gateway_resource.api_gateway_resource.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_method_settings" "api_gateway_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "*/*"

  settings {
    caching_enabled = false
    metrics_enabled = true
    logging_level   = "ERROR"
  }
}

resource "aws_api_gateway_integration" "api_proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource.id
  http_method             = aws_api_gateway_method.api_gateway_proxy_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_docker.invoke_arn
}
