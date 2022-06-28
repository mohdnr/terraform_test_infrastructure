"""
Main API handler that defines all routes.
"""

import boto3
import os
import json

from fastapi import FastAPI, Body, Response
from mangum import Mangum

app = FastAPI(
    title="AWS + FastAPI",
    description="AWS API Gateway, Lambdas and FastAPI (oh my)",
    root_path="/dev"
)

@app.get("/hello")
def hello():
    "Hello path request"
    return {"Hello": "World"}

@app.post("/body")
def body(
    response: Response,
    aws_account: str = Body(...),
    s3_key: str = Body(...),
    sns_arn: str = Body(...),
):
    return {"status": "OK", "aws_account": aws_account, "s3_key": s3_key, "sns_arn": sns_arn}

@app.get("/list")
def hello():
    client = boto3.client("s3")
    client.list_buckets()
    
    client = boto3.client("ec2")
    client.describe_instances()

    return {"Region ": os.environ['AWS_REGION']}  


def handler(event, context):
    print(vars(context))
    print(str(event))
    if "requestContext" in event and "http" in event["requestContext"]: 
        asgi_handler = Mangum(app)
        response = asgi_handler(event, context)
        return response

    elif event.get("task", "") == "private":
        return "oh no!"

    else:
        print("Handler received unrecognised event")

    return False