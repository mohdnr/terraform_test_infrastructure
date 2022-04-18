#
# Lambda: zip
#
data "archive_file" "cartography_launcher" {
  type        = "zip"
  source_file = "../images/runner/lambda.py"
  output_path = "/tmp/cartography_launcher.py.zip"
}

resource "aws_lambda_function" "cartography_launcher" {
  filename      = "/tmp/cartography_launcher.py.zip"
  function_name = "cartography_launcher"
  handler       = "lambda.handler"
  runtime       = "python3.8"
  timeout       = 10
  role          = aws_iam_role.lambda.arn

  source_code_hash = data.archive_file.cartography_launcher.output_base64sha256

  environment {
    variables = {
      CARTOGRAPHY_ECS_TASK_DEF        = aws_ecs_task_definition.cartography.family
      CARTOGRAPHY_ECS_NETWORKING      = join(", ", [for subnet in module.vpc.private_subnet_ids : subnet])
      CARTOGRAPHY_ECS_SECURITY_GROUPS = aws_security_group.cartography.id
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    billing_tag_key   = "CostCentre"
    billing_tag_value = var.billing_code
  }
}
