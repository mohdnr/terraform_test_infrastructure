resource "aws_cloudwatch_event_rule" "asset_inventory_cartography" {
  name                = "cartography"
  schedule_expression = "cron(0 22 * * ? *)"
}

resource "aws_cloudwatch_event_target" "sfn_events" {
  rule     = aws_cloudwatch_event_rule.asset_inventory_cartography.name
  arn      = aws_sfn_state_machine.asset_inventory_cartography.arn
  role_arn = aws_iam_role.asset_inventory_cartography_state_machine.arn
}

resource "aws_sfn_state_machine" "asset_inventory_cartography" {
  name     = "asset-inventory-cartography"
  role_arn = aws_iam_role.asset_inventory_cartography_state_machine.arn

  definition = jsonencode([
    {
      "Comment" : "Run daily asset inventory of cloud assets",
      "StartAt" : "Get running cartography services from previous run",
      "States" : {
        "Get running cartography services from previous run" : {
          "Type" : "Task",
          "Parameters" : {
            "Cluster" : aws_ecs_cluster.cartography.name
          },
          "Resource" : "arn:aws:states:::aws-sdk:ecs:listTasks",
          "Next" : "Is previous cartography still running"
        },
        "Is previous cartography still running" : {
          "Type" : "Choice",
          "Choices" : [
            {
              "Variable" : "$.TaskArns[0]",
              "IsPresent" : true,
              "Next" : "Pass"
            }
          ],
          "Default" : "Launch cartography"
        },
        "Pass" : {
          "Type" : "Pass",
          "End" : true
        },
        "Launch cartography" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::lambda:invoke",
          "OutputPath" : "$.Payload",
          "Parameters" : {
            "FunctionName" : "${aws_lambda_function.cartography_launcher.arn}:$LATEST"
          },
          "Retry" : [
            {
              "ErrorEquals" : [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException"
              ],
              "IntervalSeconds" : 2,
              "MaxAttempts" : 6,
              "BackoffRate" : 2
            }
          ],
          "Next" : "Wait for scans to run"
        },
        "Wait for scans to run" : {
          "Type" : "Wait",
          "Seconds" : 36000,
          "Next" : "Get running cartography services"
        },
        "Get running cartography services" : {
          "Type" : "Task",
          "Parameters" : {
            "Cluster" : aws_ecs_cluster.cartography.name
          },
          "Resource" : "arn:aws:states:::aws-sdk:ecs:listTasks",
          "Next" : "Check if cartography is still running"
        },
        "Check if cartography is still running" : {
          "Type" : "Choice",
          "Choices" : [
            {
              "Variable" : "$.TaskArns[0]",
              "IsPresent" : true,
              "Next" : "Wait"
            }
          ],
          "Default" : "Ingest data from Neo4j to Elasticsearch"
        },
        "Ingest data from Neo4j to Elasticsearch" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::ecs:runTask",
          "Parameters" : {
            "LaunchType" : "FARGATE",
            "Cluster" : aws_ecs_cluster.neo4j_ingestor.arn,
            "TaskDefinition" : aws_ecs_task_definition.neo4j_ingestor.arn
          },
          "End" : true
        },
        "Wait" : {
          "Type" : "Wait",
          "Seconds" : 1800,
          "Next" : "Get running cartography services"
        }
      }
    }
  ])

  tags = {
    CostCentre = var.billing_code
  }
}

resource "aws_iam_role" "asset_inventory_cartography_state_machine" {
  name               = "Lambda"
  assume_role_policy = data.aws_iam_policy_document.service_principal.json

  tags = {
    CostCentre = "Platform"
    Terraform  = true
  }
}

data "aws_iam_policy_document" "service_principal" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "asset_inventory_cartography_state_machine" {
  name   = "CartographyStateMachineECSLambda"
  path   = "/"
  policy = data.aws_iam_policy_document.asset_inventory_cartography_state_machine.json
}

resource "aws_iam_role_policy_attachment" "asset_inventory_cartography_state_machine" {
  role       = aws_iam_role.asset_inventory_cartography_state_machine.name
  policy_arn = aws_iam_policy.asset_inventory_cartography_state_machine.arn
}

data "aws_iam_policy_document" "asset_inventory_cartography_state_machine" {
  statement {

    effect = "Allow"

    actions = [
      "ecs:ListTasks"
    ]

    resources = [
      aws_ecs_cluster.cartography.arn
    ]
  }

  statement {

    effect = "Allow"

    actions = [
      "ecs:RunTask"
    ]

    resources = [
      aws_ecs_task_definition.neo4j_ingestor.arn
    ]
  }

  statement {

    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      aws_lambda_function.cartography_launcher.arn,
    ]
  }

}
