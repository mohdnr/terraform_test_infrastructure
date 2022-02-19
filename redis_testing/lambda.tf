data "archive_file" "lambda_zip" {
  source_dir  = "src/dist"
  output_path = "/tmp/lambda.zip"
  type        = "zip"

  depends_on = [
    null_resource.lambda_build
  ]
}

resource "aws_lambda_function" "redis_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  function_name = "lambda_redis"
  handler       = "lambda.handler"
  runtime       = "python3.8"
  timeout       = 10
  role          = aws_iam_role.lambda.arn

  vpc_config {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [aws_security_group.sg_for_lambda.id]
  }

  environment {
    variables = {
      REDIS_HOST = "/opt/otel-instrument"
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
