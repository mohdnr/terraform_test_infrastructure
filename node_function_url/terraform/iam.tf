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

resource "aws_iam_policy" "lambda_read" {
  name   = "LambdaS3EC2Read"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_read.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray_write" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_read" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_read.arn
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_read" {
  statement {
    sid    = "ECRImageAccess"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForlayer",
      "ecr:BatchGetImage"
    ]
    resources = [
      "*"
    ]
  }
}
