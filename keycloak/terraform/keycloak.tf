resource "aws_ecs_cluster" "keycloak" {
  name = "keycloak"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "keycloak" {
  name                              = "keycloak"
  cluster                           = aws_ecs_cluster.keycloak.id
  task_definition                   = aws_ecs_task_definition.keycloak.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 600

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "keycloak"
    container_port   = 8443
  }

  network_configuration {
    security_groups = [aws_security_group.keycloak.id, module.keycloak_db.proxy_security_group_id]
    subnets         = module.vpc.public_subnet_ids
  }
}

resource "aws_ecs_task_definition" "keycloak" {
  family                   = "keycloak"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 512
  memory = 1024

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "keycloak",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "DB_DATABASE",
          "value" : "keycloak"
        },
        {
          "name" : "DB_NAME",
          "value" : "keycloak"
        },
        {
          "name" : "DB_VENDOR",
          "value" : "postgres"
        },
        {
          "name" : "DB_ADDR",
          "value" : module.keycloak_db.proxy_endpoint
        },
        {
          "name" : "DB_PORT",
          "value" : "5432"
        },
        {
          "name" : "DB_SCHEMA",
          "value" : "public"
        },
        {
          "name" : "JDBC_PARAMS",
          "value" : "useSSL=true"
        }
      ],
      "essential" : true,
      "image" : "jboss/keycloak:16.1.1",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.keycloak.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-keycloak"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 8443,
          "ContainerPort" : 8443,
          "Protocol" : "tcp"
        },
        {
          "ContainerPort" : 7600,
          "Protocol" : "tcp"
        },
        {
          "ContainerPort" : 57600,
          "Protocol" : "tcp"
        },
        {
          "ContainerPort" : 55200,
          "Protocol" : "udp"
        },
        {
          "ContainerPort" : 54200,
          "Protocol" : "udp"
        }
      ],
      "secrets" : [
        {
          "name" : "KEYCLOAK_USER",
          "valueFrom" : aws_ssm_parameter.keycloak_admin_user.arn
        },
        {
          "name" : "KEYCLOAK_PASSWORD",
          "valueFrom" : aws_ssm_parameter.keycloak_admin_password.arn
        },
        {
          "name" : "DB_USER",
          "valueFrom" : aws_ssm_parameter.keycloak_db_user.arn
        },
        {
          "name" : "DB_PASSWORD",
          "valueFrom" : aws_ssm_parameter.keycloak_db_password.arn
        }
      ],
    }
  ])
}

resource "aws_cloudwatch_log_group" "keycloak" {
  name              = "/aws/ecs/keycloak"
  retention_in_days = 14
}
