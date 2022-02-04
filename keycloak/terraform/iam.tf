###
# The task execution role grants the Amazon ECS container and Fargate agents 
# permission to make AWS API calls on your behalf
###

resource "aws_iam_role" "task_execution_role" {
  name               = "keycloak_execution_role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_role.json
}

data "aws_iam_policy_document" "task_execution_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

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

resource "aws_iam_role_policy_attachment" "keycloak_policies" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.keycloak_policies.arn
}

data "aws_iam_policy_document" "keycloak_policies" {
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
      aws_ssm_parameter.keycloak_db_user.arn,
      aws_ssm_parameter.keycloak_db_password.arn,
      aws_ssm_parameter.keycloak_admin_user.arn,
      aws_ssm_parameter.keycloak_admin_password.arn,
    ]
  }
}

resource "aws_iam_policy" "keycloak_policies" {
  name   = "KeycloakTaskExecutionPolicies"
  path   = "/"
  policy = data.aws_iam_policy_document.keycloak_policies.json
}
