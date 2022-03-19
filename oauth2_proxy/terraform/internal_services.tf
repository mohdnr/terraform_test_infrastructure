resource "aws_ecs_cluster" "internal_apps" {
  name = "internal_apps"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "internal_apps" {
  name            = "internal"
  cluster         = aws_ecs_cluster.internal_apps.id
  task_definition = aws_ecs_task_definition.internal_apps.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  service_registries {
    registry_arn = aws_service_discovery_service.httpd.arn
  }

  network_configuration {
    security_groups = [aws_security_group.internal_apps.id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "internal_apps" {
  family                   = "internal_apps"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 256
  memory = 512

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "httpd",
      "cpu" : 0,
      "environment" : [],
      "essential" : true,
      "image" : "httpd:2.4",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.internal_apps.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-internal_apps"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 80,
          "ContainerPort" : 80,
          "Protocol" : "tcp"
        }
      ],
      "secrets" : [],
    }
  ])
}

resource "aws_cloudwatch_log_group" "internal_apps" {
  name              = "/aws/ecs/internal_apps"
  retention_in_days = 14
}
