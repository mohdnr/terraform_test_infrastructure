#
# IAM
#

resource "aws_iam_role" "lambda" {
  name               = "Lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = {
    CostCentre = "Platform"
    Terraform  = true
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "LambdaS3ECS"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray_write" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${var.account_id}:role/container_execution_role",
      "arn:aws:iam::${var.account_id}:role/AssetInventoryCartographyRole",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RunTask",
      "ecs:StopTask",
    ]
    resources = [
      "*"
    ]
  }

  statement {

    effect = "Allow"

    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter",
    ]
    resources = [
      aws_ssm_parameter.asset_inventory_account_list.arn,
    ]
  }

  statement {

    effect = "Allow"

    actions = [
      "servicediscovery:ListServices",
      "servicediscovery:ListInstances",
    ]
    resources = [
      "arn:aws:servicediscovery:${var.region}:${var.account_id}:*/*"
    ]
  }
}
