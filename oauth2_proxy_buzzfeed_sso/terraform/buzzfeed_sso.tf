locals {
  buzzfeed_sso_config = "../configs/upstream_configs.yml"
}

resource "aws_ecs_cluster" "buzzfeed_sso" {
  name = "buzzfeed_sso"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "buzzfeed_sso" {
  name                              = "buzzfeed_sso"
  cluster                           = aws_ecs_cluster.buzzfeed_sso.id
  task_definition                   = aws_ecs_task_definition.buzzfeed_sso.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 600

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "buzzfeed_sso"
    container_port   = 4180
  }

  network_configuration {
    security_groups = [aws_security_group.buzzfeed_sso.id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "buzzfeed_sso" {
  family                   = "buzzfeed_sso"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "entryPoint" : [
        "bash",
        "-c",
        "set -ueo pipefail; mkdir -p /sso/; echo ${base64encode(file(local.buzzfeed_sso_config))} | base64 -d > /sso/upstream_configs.yml; cat /sso/upstream_configs.yml",
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.init_sso.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-init_sso"
        }
      },
      "mountPoints" : [
        {
          "containerPath" : "/sso",
          "sourceVolume" : "buzzfeed_sso_config"
        }
      ],
      "image" : "public.ecr.aws/docker/library/bash:5",
      "readonlyRootFilesystem" : false
      "privileged" : false
      "essential" : false
      "name" : "init-sso"
    },
    {
      "dependsOn" : [
        {
          "containerName" : "init-sso"
          "condition" : "SUCCESS"
        }
      ],
      "name" : "buzzfeed_sso",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "UPSTREAM_CONFIGFILE",
          "value" : "/sso/upstream_configs.yml"
        },
        {
          "name" : "UPSTREAM_SCHEME",
          "value" : "https"
        },
        {
          "name" : "PROVIDER_URL_EXTERNAL",
          "value" : "https://auth.${var.domain_name}"
        },
        {
          "name" : "UPSTREAM_DEFAULT_EMAIL_DOMAINS",
          "value" : "cds-snc.ca"
        },
        {
          "name" : "UPSTREAM_CLUSTER",
          "value" : "dev"
        },
        {
          "name" : "METRICS_STATSD_HOST",
          "value" : "127.0.0.1"
        },
        {
          "name" : "METRICS_STATSD_PORT",
          "value" : "8125"
        },
        {
          "name" : "SESSION_COOKIE_SECURE",
          "value" : "false"
        },
        {
          "name" : "LOGGING_LEVEL",
          "value" : "debug"
        },
        {
          "name" : "VIRTUAL_HOST",
          "value" : "*"
        },
      ],
      "mountPoints" : [
        {
          "containerPath" : "/sso",
          "sourceVolume" : "buzzfeed_sso_config"
        }
      ],
      "essential" : true,
      "image" : "buzzfeed/sso:v3.0.0",
      "entrypoint" : ["/bin/sso-proxy"],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.buzzfeed_sso.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-buzzfeed_sso"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 4180,
          "ContainerPort" : 4180,
          "Protocol" : "tcp"
        }
      ],
      "secrets" : [
        {
          "name" : "SESSION_COOKIE_SECRET",
          "valueFrom" : aws_ssm_parameter.session_cookie_secret.arn
        },
        {
          "name" : "CLIENT_ID",
          "valueFrom" : aws_ssm_parameter.buzzfeed_sso_client_id.arn
        },
        {
          "name" : "CLIENT_SECRET",
          "valueFrom" : aws_ssm_parameter.buzzfeed_sso_client_secret.arn
        },
      ],
    },
  ])
  volume {
    name = "buzzfeed_sso_config"
  }
}

resource "aws_cloudwatch_log_group" "buzzfeed_sso" {
  name              = "/aws/ecs/buzzfeed_sso"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "init_sso" {
  name              = "/aws/ecs/init_sso"
  retention_in_days = 14
}
