#
# Lambda: Docker image
#
resource "aws_lambda_function" "lambda_docker" {
  function_name = "lambda_docker"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda.repository_url}:latest"
  timeout       = 10
  role          = aws_iam_role.lambda.arn

  environment {
    variables = {
      NEW_RELIC_ACCOUNT_ID               = var.new_relic_account
      NEW_RELIC_LAMBDA_HANDLER           = "lambda.handler"
      NEW_RELIC_LICENSE_KEY              = var.new_relic_license_key
      NEW_RELIC_EXTENSION_LOGS_ENABLED   = true
      NEW_RELIC_LAMBDA_EXTENSION_ENABLED = true
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

# Allow the API gateway to invoke this lambda function
resource "aws_lambda_permission" "api_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_docker.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*/*"
}
