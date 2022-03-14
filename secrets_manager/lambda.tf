data "archive_file" "lambda_zip" {
  source_dir  = "src/dist"
  output_path = "/tmp/lambda.zip"
  type        = "zip"

  depends_on = [
    null_resource.lambda_build
  ]
}

resource "aws_lambda_function" "secret_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  function_name = "lambda_secret"
  handler       = "lambda.handler"
  runtime       = "python3.8"
  timeout       = 10
  role          = aws_iam_role.lambda.arn

  environment {
    variables = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

resource "null_resource" "lambda_build" {
  triggers = {
    handler = base64sha256(file("src/lambda.py"))
    build   = base64sha256(file("src/build.sh"))
  }

  provisioner "local-exec" {
    command = "${path.module}/src/build.sh"
  }
}
