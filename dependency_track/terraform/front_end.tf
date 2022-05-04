locals {
  dependency_track_front_end_service_name = "dependency_track_front_end"
}

resource "aws_ecs_service" "dependency_track_front_end" {
  name                              = local.dependency_track_front_end_service_name
  cluster                           = aws_ecs_cluster.software_dependency_tracking.id
  task_definition                   = aws_ecs_task_definition.dependency_track_front_end.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 600

  load_balancer {
    target_group_arn = aws_lb_target_group.dependency_track_front_end.arn
    container_name   = local.dependency_track_front_end_service_name
    container_port   = 8080
  }

  network_configuration {
    security_groups = [aws_security_group.dependency_track.id, module.dependency_track_db.proxy_security_group_id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "dependency_track_front_end" {
  family                   = local.dependency_track_front_end_service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 2048
  memory = 4096

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : local.dependency_track_front_end_service_name,
      "cpu" : 0,
      "environment" : [
        {
          "name" : "API_BASE_URL",
          "value" : "https://${aws_lb.dependency_track.dns_name}:8081"
        }
      ],
      "essential" : true,
      "image" : "dependencytrack/frontend:latest",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.dependency_track_front_end.name,
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
      ]
    }
  ])
}

resource "aws_cloudwatch_log_group" "dependency_track_front_end" {
  name              = "/aws/ecs/${local.dependency_track_front_end_service_name}"
  retention_in_days = 14
}
