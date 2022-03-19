resource "aws_ecs_cluster" "buzzfeed_sso_auth" {
  name = "buzzfeed_sso_auth"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "buzzfeed_sso_auth" {
  name                              = "buzzfeed_sso_auth"
  cluster                           = aws_ecs_cluster.buzzfeed_sso_auth.id
  task_definition                   = aws_ecs_task_definition.buzzfeed_sso_auth.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 600


  load_balancer {
    target_group_arn = aws_lb_target_group.sso_auth.arn
    container_name   = "buzzfeed_sso_auth"
    container_port   = 4180
  }
  network_configuration {
    security_groups = [aws_security_group.buzzfeed_sso.id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "buzzfeed_sso_auth" {
  family                   = "buzzfeed_sso_auth"
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
        "set -ueo pipefail; mkdir -p /sso/; echo ${var.buzzfeed_sso_sso_credentials} | base64 -d > /sso/credentials.json",
      ],
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
      "name" : "buzzfeed_sso_auth",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "AUTHORIZE_EMAIL_DOMAINS",
          "value" : "cds-snc.ca"
        },
        {
          "name" : "PROVIDER_GOOGLE_GOOGLE_CREDENTIALS",
          "value" : "/sso/credentials.json"
        },
        {
          "name" : "AUTHORIZE_PROXY_DOMAINS",
          "value" : "*"
        },
        {
          "name" : "SERVER_SCHEME",
          "value" : "https"
        },
        {
          "name" : "SERVER_HOST",
          "value" : "auth.${var.domain_name}"
        },
        {
          "name" : "UPSTREAM_DEFAULT_EMAIL_DOMAINS",
          "value" : "cds-snc.ca"
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
          "name" : "PROVIDER_GOOGLE_TYPE",
          "value" : "google"
        },
        {
          "name" : "PROVIDER_GOOGLE_SLUG",
          "value" : "google"
        },
        {
          "name" : "SESSION_COOKIE_SECURE",
          "value" : "false"
        },
        {
          "name" : "CLUSTER",
          "value" : "dev"
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
      "essential" : true,
      "image" : "buzzfeed/sso:v3.0.0",
      "entrypoint" : ["/bin/sso-auth"],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.buzzfeed_sso_auth.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-buzzfeed_sso_auth"
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
          "name" : "SESSION_KEY",
          "valueFrom" : aws_ssm_parameter.session_key.arn
        },
        {
          "name" : "SESSION_COOKIE_SECRET",
          "valueFrom" : aws_ssm_parameter.session_cookie_secret.arn
        },
        {
          "name" : "CLIENT_PROXY_ID",
          "valueFrom" : aws_ssm_parameter.buzzfeed_sso_client_id.arn
        },
        {
          "name" : "CLIENT_PROXY_SECRET",
          "valueFrom" : aws_ssm_parameter.buzzfeed_sso_client_secret.arn
        },
        {
          "name" : "PROVIDER_GOOGLE_CLIENT_ID",
          "valueFrom" : aws_ssm_parameter.buzzfeed_sso_google_client_id.arn
        },
        {
          "name" : "PROVIDER_GOOGLE_CLIENT_SECRET",
          "valueFrom" : aws_ssm_parameter.buzzfeed_sso_google_client_secret.arn
        },
      ],
    },
  ])
  volume {
    name = "buzzfeed_sso_config"
  }
}

resource "aws_cloudwatch_log_group" "buzzfeed_sso_auth" {
  name              = "/aws/ecs/buzzfeed_sso_auth"
  retention_in_days = 14
}
