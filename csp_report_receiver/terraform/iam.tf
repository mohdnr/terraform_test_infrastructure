resource "aws_iam_role" "task_execution_role" {
  name               = "csp_reports_execution_role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_role.json
}

data "aws_iam_policy_document" "task_execution_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policies" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "container_registery_policies" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_role_policy_attachment" "csp_reports_policies" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.csp_reports_policies.arn
}

resource "aws_iam_policy" "csp_reports_policies" {
  name   = "CSPReportsTaskExecutionPolicies"
  path   = "/"
  policy = data.aws_iam_policy_document.csp_reports_policies.json
}

data "aws_iam_policy_document" "csp_reports_policies" {

  statement {

    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [
      "*"
    ]
  }

  statement {

    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:ca-central-1:${var.account_id}:log-group:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameters",
    ]
    resources = [
      "arn:aws:ssm:ca-central-1:${var.account_id}:parameter/csp-reports-config",
      aws_ssm_parameter.app_key.arn,
      aws_ssm_parameter.db_host.arn,
      aws_ssm_parameter.db_username.arn,
      aws_ssm_parameter.db_database.arn,
      aws_ssm_parameter.db_password.arn
    ]
  }
}
