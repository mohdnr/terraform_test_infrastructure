data "archive_file" "lambda_zip" {
  source_dir  = "src/dist"
  output_path = "/tmp/lambda.zip"
  type        = "zip"

  depends_on = [
    null_resource.lambda_build
  ]
}

resource "aws_lambda_function" "api_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  function_name = "lambda_api"
  handler       = "lambda.handler"
  runtime       = "python3.8"
  memory_size   = 1536
  timeout       = 300
  role          = aws_iam_role.lambda.arn

  tracing_config {
    mode = "Active"
  }

  tags = {
    CostCentre = "Platform"
    Terraform  = true
  }
}

resource "null_resource" "lambda_build" {
  triggers = {
    handler      = base64sha256(file("src/lambda.py"))
    requirements = base64sha256(file("src/requirements.txt"))
    build        = base64sha256(file("src/build.sh"))
  }

  provisioner "local-exec" {
    command = "${path.module}/src/build.sh"
  }
}

resource "aws_lambda_function_url" "function_url_test" {
  function_name      = aws_lambda_function.api_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    max_age           = 86400
  }
}
