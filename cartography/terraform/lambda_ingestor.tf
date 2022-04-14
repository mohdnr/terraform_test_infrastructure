#
# Lambda: zip
#
data "archive_file" "neo4j_ingest_runner" {
  type        = "zip"
  source_file = "../images/runner_ingest_all/lambda.py"
  output_path = "/tmp/neo4j_ingest_runner.zip"
}

resource "aws_lambda_function" "neo4j_ingest_runner" {
  filename      = "/tmp/neo4j_ingest_runner.zip"
  function_name = "neo4j_ingest_runner"
  handler       = "lambda.handler"
  runtime       = "python3.8"
  timeout       = 10
  role          = aws_iam_role.lambda.arn

  source_code_hash = data.archive_file.neo4j_ingest_runner.output_base64sha256

  environment {
    variables = {
      ELASTIC_URL                     = "${aws_elasticsearch_domain.cartography.endpoint}:443"
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
