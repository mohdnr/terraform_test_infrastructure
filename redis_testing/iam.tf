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

resource "aws_iam_role_policy_attachment" "lambda_elasticache_full_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess"
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
