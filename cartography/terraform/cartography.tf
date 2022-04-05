locals {
  aws_config_file   = "../configs/roles"
  aws_config_script = "../configs/setup_credentials.sh"
}

resource "aws_ecs_cluster" "cartography" {
  name = "cartography"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  name                = "cartography"
  schedule_expression = "cron(0 5 * * ? *)"
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  rule      = aws_cloudwatch_event_rule.event_rule.name
  target_id = "cartography"
  arn       = aws_ecs_cluster.cartography.arn
  role_arn  = aws_iam_role.container_execution_role.arn
  ecs_target {
    launch_type         = "FARGATE"
    platform_version    = "LATEST"
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.cartography.arn
    network_configuration {
      security_groups = [aws_security_group.cartography.id]
      subnets         = module.vpc.private_subnet_ids
    }
  }
}

resource "aws_ecs_task_definition" "cartography" {
  family                   = "cartography"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 2048
  memory = 4096

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "entryPoint" : [
        "bash",
        "-c",
        "set -ueo pipefail; mkdir -p /config/; echo ${base64encode(file(local.aws_config_file))} | base64 -d > /config/role_config; echo ${base64encode(file(local.aws_config_script))} | base64 -d > /config/setup_credentials.sh; chmod +x /config/setup_credentials.sh; cat /config/setup_credentials.sh; cat /config/role_config",
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.init_cartography.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-init_cartography"
        }
      },
      "mountPoints" : [
        {
          "containerPath" : "/config",
          "sourceVolume" : "cartography_config"
        }
      ],
      "image" : "public.ecr.aws/docker/library/bash:5",
      "readonlyRootFilesystem" : false
      "privileged" : false
      "essential" : false
      "name" : "init-cartography"
    },
    {
      "entryPoint" : [
        "/config/setup_credentials.sh"
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.init_cartography.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-init_cartography"
        }
      },
      "mountPoints" : [
        {
          "containerPath" : "/config",
          "sourceVolume" : "cartography_config"
        },
        {
          "containerPath" : "~/.aws",
          "sourceVolume" : "aws_config"
        }
      ],
      "image" : "public.ecr.aws/amazonlinux/amazonlinux:latest",
      "readonlyRootFilesystem" : false
      "privileged" : false
      "essential" : false
      "dependsOn" : [
        {
          "containerName" : "init-cartography"
          "condition" : "SUCCESS"
        }
      ],
      "name" : "init-aws-config"
    },
    {
      "dependsOn" : [
        {
          "containerName" : "init-aws-config"
          "condition" : "SUCCESS"
        }
      ],
      "name" : "cartography",
      "command" : [
        "--neo4j-uri",
        "bolt://neo4j.internal.local:7687",
        "--neo4j-user",
        "neo4j",
        "--neo4j-password-env-var",
        "NEO4J_PASSWORD",
        "--aws-sync-all-profiles"
      ],
      "cpu" : 0,
      "environment" : [
        {
          "name" : "AWS_CONFIG_FILE",
          "value" : "/config/role_config"
        },
      ],
      "essential" : true,
      "mountPoints" : [
        {
          "containerPath" : "/config",
          "sourceVolume" : "cartography_config"
        },
        {
          "containerPath" : "~/.aws",
          "sourceVolume" : "aws_config"
        }
      ],
      "image" : "williamjackson/cartography",
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
          "name" : "NEO4J_PASSWORD",
          "valueFrom" : aws_ssm_parameter.neo4j_password.arn
        }
      ],
    },
  ])

  volume {
    name = "cartography_config"
  }

  volume {
    name = "aws_config"
  }
}

resource "aws_cloudwatch_log_group" "cartography" {
  name              = "/aws/ecs/cartography"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "init_cartography" {
  name              = "/aws/ecs/init_cartography"
  retention_in_days = 14
}
