#
# Lambda
#

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "/tmp/lambda.py.zip"
}

resource "aws_lambda_function" "account_management" {
  filename      = "/tmp/lambda.py.zip"
  function_name = "account_management"
  handler       = "lambda.handler"
  runtime       = "python3.9"
  timeout       = 10
  role          = aws_iam_role.lambda.arn

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  tags = {
    CostCentre = "Platform"
    Terraform  = true
  }
}

data "archive_file" "workflow_management_lambda_zip" {
  type        = "zip"
  source_file = "workflow.py"
  output_path = "/tmp/workflow.py.zip"
}

resource "aws_lambda_function" "workflow_management" {
  filename      = "/tmp/workflow.py.zip"
  function_name = "workflow_management"
  handler       = "workflow.handler"
  runtime       = "python3.9"
  timeout       = 10
  role          = aws_iam_role.lambda.arn

  source_code_hash = data.archive_file.workflow_management_lambda_zip.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  tags = {
    CostCentre = "Platform"
    Terraform  = true
  }
}
