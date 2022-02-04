resource "aws_ecs_cluster" "keycloak" {
  name = "keycloak"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "keycloak" {
  name            = "keycloak"
  cluster         = aws_ecs_cluster.keycloak.id
  task_definition = aws_ecs_task_definition.keycloak.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.inbound_to_keycloak.id]
    subnets          = module.vpc.public_subnet_ids
    assign_public_ip = true
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
      "command" : ["start-dev"],
      "cpu" : 0,
      "environment" : [
        {
          "name" : "DB_DATABASE",
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
          "hostPort" : 8080,
          "protocol" : "tcp",
          "containerPort" : 8080
        }
      ],
      "secrets" : [
        {
          "name" : "KEYCLOAK_ADMIN",
          "valueFrom" : aws_ssm_parameter.keycloak_admin_user.arn
        },
        {
          "name" : "KEYCLOAK_ADMIN_PASSWORD",
          "valueFrom" : aws_ssm_parameter.keycloak_admin_password.arn
        },
        {
          "name" : "DB_USER",
          "valueFrom" : aws_ssm_parameter.keycloak_db_user.arn
        },
        {
          "name" : "DB_PWD",
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
