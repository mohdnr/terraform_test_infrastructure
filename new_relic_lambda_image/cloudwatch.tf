#
# API Gateway CloudWatch logging
#
resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  # checkov:skip=CKV_AWS_158:Default service key encryption is acceptable
  name              = "/aws/api-gateway/${aws_api_gateway_rest_api.api_gateway.name}"
  retention_in_days = 14
}

# This account is used by all API Gateway resources in a region
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
}

resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name               = "ApiGatewayCloudwatchRole"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_logging_policy_attachment" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

data "aws_iam_policy_document" "api_gateway_assume_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}
