###
# The task execution role grants the Amazon ECS container and Fargate agents 
# permission to make AWS API calls on your behalf
###

resource "aws_iam_role" "task_execution_role" {
  name               = "buzzfeed_sso_execution_role"
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


resource "aws_iam_role_policy_attachment" "buzzfeed_sso_policies" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.buzzfeed_sso_policies.arn
}

data "aws_iam_policy_document" "buzzfeed_sso_policies" {
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
      "ssm:DescribeParameters",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.buzzfeed_sso_google_client_id.arn,
      aws_ssm_parameter.buzzfeed_sso_google_client_secret.arn,
      aws_ssm_parameter.session_key.arn,
      aws_ssm_parameter.session_cookie_secret.arn,
      aws_ssm_parameter.buzzfeed_sso_client_id.arn,
      aws_ssm_parameter.buzzfeed_sso_client_secret.arn,
    ]
  }
}

resource "aws_iam_policy" "buzzfeed_sso_policies" {
  name   = "Buzzfeed_ssoTaskExecutionPolicies"
  path   = "/"
  policy = data.aws_iam_policy_document.buzzfeed_sso_policies.json
}
