locals {
  dependency_track_api_service_name = "dependency_track_api"
}

resource "aws_ecs_service" "dependency_track_api" {
  name                              = local.dependency_track_api_service_name
  cluster                           = aws_ecs_cluster.software_dependency_tracking.id
  task_definition                   = aws_ecs_task_definition.dependency_track_api.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 600

  load_balancer {
    target_group_arn = aws_lb_target_group.dependency_track_api.arn
    container_name   = local.dependency_track_api_service_name
    container_port   = 8080
  }

  network_configuration {
    security_groups = [aws_security_group.dependency_track.id, module.dependency_track_db.proxy_security_group_id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "dependency_track_api" {
  family                   = local.dependency_track_api_service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 4096
  memory = 16384

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : local.dependency_track_api_service_name,
      "cpu" : 4096,
      "environment" : [
        {
          "name" : "ALPINE_DATABASE_MODE",
          "value" : "external"
        },
        {
          "name" : "ALPINE_DATABASE_URL",
          "value" : module.dependency_track_db.proxy_endpoint
        },
        {
          "name" : "ALPINE_DATABASE_DRIVER",
          "value" : "org.postgresql.Driver"
        }
      ],
      "essential" : true,
      "image" : "dependencytrack/apiserver:latest",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.dependency_track_api.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-dependency_track"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 8080,
          "ContainerPort" : 8080,
          "Protocol" : "tcp"
        }
      ],
      "secrets" : [
        {
          "name" : "ALPINE_DATABASE_USERNAME",
          "valueFrom" : aws_ssm_parameter.dependency_track_db_user.arn
        },
        {
          "name" : "ALPINE_DATABASE_PASSWORD",
          "valueFrom" : aws_ssm_parameter.dependency_track_db_password.arn
        }
      ],
    }
  ])
}

resource "aws_cloudwatch_log_group" "dependency_track_api" {
  name              = "/aws/ecs/${local.dependency_track_api_service_name}"
  retention_in_days = 14
}
