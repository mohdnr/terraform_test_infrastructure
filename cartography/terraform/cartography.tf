locals {
  aws_config_file = "../configs/roles"
}

resource "aws_ecs_cluster" "cartography" {
  name = "cartography"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "cartography" {
  family                   = "cartography"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 4096
  memory = 16384

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "cartography",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "AWS_CONFIG_FILE",
          "value" : "/config/role_config"
        },
        {
          "name" : "AWS_PROFILE_DATA",
          "value" : "${base64encode(file(local.aws_config_file))}"
        },
        {
          "name" : "NEO4J_URI",
          "value" : "bolt://neo4j.internal.local:7687"
        },
        {
          "name" : "NEO4J_USER",
          "value" : "neo4j"
        },
      ],
      "essential" : true,
      "image" : "${aws_ecr_repository.cartography.repository_url}:latest",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.cartography.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-cartography"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 443,
          "ContainerPort" : 443,
          "Protocol" : "tcp"
        }
      ],
      "secrets" : [
        {
          "name" : "NEO4J_SECRETS_PASSWORD",
          "valueFrom" : aws_ssm_parameter.neo4j_password.arn
        }
      ],
    },
  ])
}

resource "aws_cloudwatch_log_group" "cartography" {
  name              = "/aws/ecs/cartography"
  retention_in_days = 14
}
