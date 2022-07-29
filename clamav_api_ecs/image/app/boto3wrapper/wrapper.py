from boto3 import Session
import os
from clamav_scanner.common import AWS_ENDPOINT_URL, AWS_ROLE_TO_ASSUME


def get_session(credentials=None):

    options = {"region_name": "ca-central-1"}

    use_localstack = os.environ.get("AWS_LOCALSTACK", False)
    if use_localstack:
        options["aws_access_key_id"] = "foo"
        options["aws_secret_access_key"] = "bar"
    elif credentials:
        options["aws_access_key_id"] = credentials["AccessKeyId"]
        options["aws_secret_access_key"] = credentials["SecretAccessKey"]
        options["aws_session_token"] = credentials["SessionToken"]

    return Session(**options)


def get_credentials(aws_account):
    if aws_account is None:
        return None

    sts = get_session().client("sts", endpoint_url=AWS_ENDPOINT_URL)
    assumed_role_object = sts.assume_role(
        RoleArn=f"arn:aws:iam::{aws_account}:role/{AWS_ROLE_TO_ASSUME}",
        RoleSessionName="scan-files",
    )
    return assumed_role_object["Credentials"]
