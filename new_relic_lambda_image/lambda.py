"""
Main API handler that defines all routes.
"""

import boto3
import os
import awsgi
from flask import Flask
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask("api")
app.wsgi_app = ProxyFix(app.wsgi_app)  # type: ignore

@app.route("/hello")
def hello():
    "Hello path request"
    return {"Hello": "World"}

@app.route("/list")
def list_boto():
    client = boto3.client("s3")
    client.list_buckets()
    
    client = boto3.client("ec2")
    client.describe_instances()

    return {"Region ": os.environ['AWS_REGION']}  

def handler(event, context):
    return awsgi.response(app, event, context)
