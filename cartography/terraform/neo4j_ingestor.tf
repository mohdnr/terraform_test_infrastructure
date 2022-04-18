locals {
  elasticsearch_config_file = "../configs/elasticsearch/es-index.json"
}

resource "aws_ecs_cluster" "neo4j_ingestor" {
  name = "neo4j_ingestor"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "neo4j_ingestor" {
  family                   = "neo4j_ingestor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 2048
  memory = 4096

  execution_role_arn = aws_iam_role.container_execution_role.arn
  task_role_arn      = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "neo4j_ingestor",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "NEO4J_URI",
          "value" : "bolt://neo4j.internal.local:7687"
        },
        {
          "name" : "NEO4J_USER",
          "value" : "neo4j"
        },
        {
          "name" : "ELASTIC_TLS_ENABLED",
          "value" : "True"
        },
        {
          "name" : "ELASTIC_INDEX",
          "value" : "cartography"
        },
        {
          "name" : "ELASTIC_DRY_RUN",
          "value" : "False"
        },
        {
          "name" : "ELASTIC_INDEX_SPEC",
          "value" : "/opt/es-index/es-index.json"
        },
        {
          "name" : "ELASTIC_URL",
          "value" : "${aws_elasticsearch_domain.cartography.endpoint}:443"
        }
      ],
      "essential" : true,
      "image" : "${aws_ecr_repository.neo4j_ingestor.repository_url}:latest",
      "entryPoint" : ["/bin/bash", "-c", join(" ", [
        "set -ueo pipefail; echo ${base64encode(file(local.elasticsearch_config_file))} | base64 -d > /opt/es-index/es-index.json;",
        "python3 /app/elastic_ingestor.py;",
      ])],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.neo4j_ingestor.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-neo4j_ingestor"
        }
      },
      "secrets" : [
        {
          "name" : "NEO4J_SECRETS_PASSWORD",
          "valueFrom" : aws_ssm_parameter.neo4j_password.arn
        },
        {
          "name" : "ELASTICSEARCH_USER",
          "valueFrom" : aws_ssm_parameter.elasticsearch_user.arn
        },
        {
          "name" : "ELASTICSEARCH_PASSWORD",
          "valueFrom" : aws_ssm_parameter.elasticsearch_password.arn
        }
      ],
    },
  ])

  volume {
    name = "elasticsearch-index-volume"
  }
}

resource "aws_cloudwatch_log_group" "neo4j_ingestor" {
  name              = "/aws/ecs/neo4j_ingestor"
  retention_in_days = 14
}
