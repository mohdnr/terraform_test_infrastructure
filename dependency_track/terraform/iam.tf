###
# The task execution role grants the Amazon ECS container and Fargate agents 
# permission to make AWS API calls on your behalf
###

resource "aws_iam_role" "task_execution_role" {
  name               = "dependency_track_execution_role"
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


resource "aws_iam_role_policy_attachment" "dependency_track_policies" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.dependency_track_policies.arn
}

data "aws_iam_policy_document" "dependency_track_policies" {
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
      aws_ssm_parameter.dependency_track_db_user.arn,
      aws_ssm_parameter.dependency_track_db_password.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:DescribeMountTargets",
    ]
    resources = [
      aws_efs_file_system.dependency_track.arn
    ]
  }
}

resource "aws_iam_policy" "dependency_track_policies" {
  name   = "DependencyTrackTaskExecutionPolicies"
  path   = "/"
  policy = data.aws_iam_policy_document.dependency_track_policies.json
}
