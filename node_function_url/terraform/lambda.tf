#
# Lambda: Docker image
#
resource "aws_lambda_function" "lambda_docker" {
  function_name = "lambda_docker"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda.repository_url}:latest"
  timeout       = 10
  role          = aws_iam_role.lambda.arn

  tracing_config {
    mode = "Active"
  }

  tags = {
    CostCentre = "Platform"
    Terraform  = true
  }
}

resource "aws_lambda_function_url" "function_url_test" {
  function_name      = aws_lambda_function.lambda_docker.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    max_age           = 86400
  }
}
