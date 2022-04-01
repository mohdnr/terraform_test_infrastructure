locals {
  policy_file = "../configs/policy.yml"
}

resource "aws_ecs_cluster" "pomerium" {
  name = "pomerium"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "pomerium" {
  name                              = "pomerium"
  cluster                           = aws_ecs_cluster.pomerium.id
  task_definition                   = aws_ecs_task_definition.pomerium.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 600

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "pomerium"
    container_port   = 443
  }

  network_configuration {
    security_groups = [aws_security_group.pomerium.id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "pomerium" {
  family                   = "pomerium"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 2048
  memory = 4096

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "pomerium",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "POLICY",
          "value" : base64encode(file(local.policy_file))
        },
        {
          "name" : "IDP_PROVIDER",
          "value" : "azure"
        },
        {
          "name" : "AUTHENTICATE_SERVICE_URL",
          "value" : "https://azure.${var.domain_name}"
        },
        {
          "name" : "AUTOCERT",
          "value" : "FALSE"
        },
        {
          "name" : "INSECURE_SERVER",
          "value" : "true"
        },
        {
          "name" : "LOG_LEVEL",
          "value" : "debug"
        },
        {
          "name" : "POMERIUM_DEBUG",
          "value" : "true"
        },
      ],
      "essential" : true,
      "image" : "pomerium/pomerium:latest",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.pomerium.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-pomerium"
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
          "name" : "SHARED_SECRET",
          "valueFrom" : aws_ssm_parameter.pomerium_client_id.arn
        },
        {
          "name" : "COOKIE_SECRET",
          "valueFrom" : aws_ssm_parameter.pomerium_client_secret.arn
        },
        {
          "name" : "IDP_CLIENT_ID",
          "valueFrom" : aws_ssm_parameter.pomerium_azure_client_id.arn
        },
        {
          "name" : "IDP_CLIENT_SECRET",
          "valueFrom" : aws_ssm_parameter.pomerium_azure_client_secret.arn
        },
        {
          "name" : "IDP_PROVIDER_URL",
          "valueFrom" : aws_ssm_parameter.pomerium_azure_provider_url.arn
        },
      ],
    },
  ])
}

resource "aws_cloudwatch_log_group" "pomerium" {
  name              = "/aws/ecs/pomerium"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "init_sso" {
  name              = "/aws/ecs/init_sso"
  retention_in_days = 14
}
