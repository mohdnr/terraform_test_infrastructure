import base64
import boto3
import json
from os import environ

ecs = boto3.client("ecs")
servicediscovery = boto3.client('servicediscovery')

def handler(event, context): 
  instance_list = []
  response = servicediscovery.list_services()
  for service in response['Services']:
    if service['Name'] == "neo4j":
      li_response = servicediscovery.list_instances(ServiceId=service['Id'])
      for instance in li_response['Instances']:
        if instance['Attributes']['AWS_INIT_HEALTH_STATUS'] == 'HEALTHY':
          instance_list.append(instance['Attributes']['AWS_INSTANCE_IPV4'])
          
  for instance in instance_list:
    response = ecs.run_task(
        taskDefinition='neo4j_ingestor',
        launchType='FARGATE',
        cluster='neo4j_ingestor',
        platformVersion='LATEST',
        count=1,
        networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': environ.get("CARTOGRAPHY_ECS_NETWORKING").split(","),
                'securityGroups': [environ.get("CARTOGRAPHY_ECS_SECURITY_GROUPS")]
            }
        },
        overrides={
          'containerOverrides': [
            {
              "name" : "neo4j_ingestor",
              'environment': [
                  {
                    "name" : "NEO4J_URI",
                    "value" : f"bolt://{instance}:7687"
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
                    "value" : environ.get("ELASTIC_URL")
                  }
              ],
            }
          ]
        }
    )