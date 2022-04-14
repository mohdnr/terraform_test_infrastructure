resource "aws_ecs_cluster" "neo4j" {
  name = "neo4j"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "neo4j" {
  name                              = "neo4j"
  cluster                           = aws_ecs_cluster.neo4j.id
  task_definition                   = aws_ecs_task_definition.neo4j.arn
  desired_count                     = length(local.trusted_role_arns)
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 600

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "neo4j"
    container_port   = 7474
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.bolt.arn
    container_name   = "neo4j"
    container_port   = 7687
  }

  service_registries {
    registry_arn = aws_service_discovery_service.neo4j.arn
  }

  network_configuration {
    security_groups = [aws_security_group.cartography.id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "neo4j" {
  family                   = "neo4j"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 2048
  memory = 8192

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "neo4j",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "NEO4J_dbms_memory_pagecache_size",
          "value" : "4G"
        },
        {
          "name" : "NEO4J_dbms.memory.heap.initial_size",
          "value" : "4G"
        },
        {
          "name" : "NEO4J_dbms_memory_heap_max__size",
          "value" : "4G"
        },
        {
          "name" : "NEO4J_ACCEPT_LICENSE_AGREEMENT",
          "value" : "yes"
        }
      ],
      "essential" : true,
      "image" : "neo4j:3.5",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.neo4j.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-neo4j"
        }
      },
      "ulimits" : [
        {
          "name" : "nofile",
          "softLimit" : 400000,
          "hardLimit" : 400000
        }
      ],
      "portMappings" : [
        {
          "hostPort" : 7474,
          "ContainerPort" : 7474,
          "Protocol" : "tcp"
        },
        {
          "hostPort" : 7473,
          "ContainerPort" : 7473,
          "Protocol" : "tcp"
        },
        {
          "hostPort" : 7687,
          "ContainerPort" : 7687,
          "Protocol" : "tcp"
        }
      ],
      "secrets" : [
        {
          "name" : "NEO4J_AUTH",
          "valueFrom" : aws_ssm_parameter.neo4j_auth.arn
        }
      ],
    }
  ])
}

resource "aws_cloudwatch_log_group" "neo4j" {
  name              = "/aws/ecs/neo4j"
  retention_in_days = 14
}
