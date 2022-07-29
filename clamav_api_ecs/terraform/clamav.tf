locals {
  aws_config_file = "../configs/roles"
}

resource "aws_ecs_cluster" "clamav" {
  name = "clamav"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "clamav" {
  name            = "clamav"
  cluster         = aws_ecs_cluster.clamav.id
  task_definition = aws_ecs_task_definition.clamav.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.clamav.id]
    subnets          = module.vpc.public_subnet_ids
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "clamav" {
  family                   = "clamav"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 4096
  memory = 16384

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "clamav",
      "cpu" : 4096,
      "environment" : [
        {
          "name" : "PORT",
          "value" : "8000"
        },
        {
          "name" : "BIND",
          "value" : "0.0.0.0:8000"
        },
        {
          "name" : "AV_DEFINITION_S3_BUCKET",
          "value" : module.clamav-defs.s3_bucket_id
        },
        {
          "name" : "AV_DEFINITION_PATH",
          "value" : "/tmp/clamav"
        },
        {
          "name" : "CLAMAVLIB_PATH",
          "value" : "/etc/clamav"
        },
        {
          "name" : "CLAMSCAN_PATH",
          "value" : "/usr/bin/clamdscan"
        },
        {
          "name" : "FRESHCLAM_PATH",
          "value" : "/usr/bin/freshclam"
        }
      ],
      "essential" : true,
      "image" : "${aws_ecr_repository.clamav.repository_url}:latest",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.clamav.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-clamav"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 8000,
          "ContainerPort" : 8000,
          "Protocol" : "tcp"
        }
      ],
      "secrets" : [],
    },
  ])
}

resource "aws_cloudwatch_log_group" "clamav" {
  name              = "/aws/ecs/clamav"
  retention_in_days = 14
}
