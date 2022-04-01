resource "aws_ecs_cluster" "pomerium_auth" {
  name = "pomerium_auth"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "pomerium_auth" {
  name            = "pomerium_auth"
  cluster         = aws_ecs_cluster.pomerium_auth.id
  task_definition = aws_ecs_task_definition.pomerium_auth.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  service_registries {
    registry_arn = aws_service_discovery_service.azure.arn
  }

  network_configuration {
    security_groups = [aws_security_group.pomerium.id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "pomerium_auth" {
  family                   = "pomerium_auth"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 1024
  memory = 2048

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "pomerium_auth",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "IDP_PROVIDER",
          "value" : "azure"
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
      "image" : "pomerium/verify:latest",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.pomerium_auth.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-pomerium_auth"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 8000,
          "ContainerPort" : 8000,
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

resource "aws_cloudwatch_log_group" "pomerium_auth" {
  name              = "/aws/ecs/pomerium_auth"
  retention_in_days = 14
}
