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
