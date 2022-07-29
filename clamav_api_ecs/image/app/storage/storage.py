from boto3wrapper.wrapper import get_session, get_credentials
from logger import log
from os import environ
from tempfile import TemporaryFile
from urllib.parse import urlparse
from uuid import uuid4


def get_file(save_path, aws_account=None, ref_only=False):
    parsed_save_path = urlparse(save_path)
    bucket = parsed_save_path.netloc
    key = parsed_save_path.path.lstrip("/")

    if environ.get("AWS_LOCALSTACK", False):
        client = get_session().resource("s3", endpoint_url="http://localstack:4566")
    else:
        credentials = get_credentials(aws_account)
        client = get_session(credentials).resource("s3")

    try:
        basename = key.split("/")[-1].strip()

        file = TemporaryFile()
        if ref_only:
            client.Bucket(bucket).download_fileobj(basename, file)
        else:
            client.Bucket(bucket).download_fileobj(basename, file)
            file.seek(0)
            file = file.read()

        log.info(f"Downloaded {key} from {bucket}")
        return file
    except Exception as err:
        log.error(f"Error downloading {key} from {bucket}")
        log.error(err)
        return False


def get_object(record, ref_only=False):

    if environ.get("AWS_LOCALSTACK", False):
        client = get_session().resource("s3", endpoint_url="http://localstack:4566")
    else:
        client = get_session().resource("s3")

    obj = client.Object(record["s3"]["bucket"]["name"], record["s3"]["object"]["key"])
    try:
        if ref_only:
            body = obj.get()["Body"]
        else:
            body = obj.get()["Body"].read()

        log.info(
            f"Downloaded {record['s3']['object']['key']} from {record['s3']['bucket']['name']} with length {len(body)}"
        )
        return body
    except Exception as err:
        log.error(
            f"Error downloading {record['s3']['object']['key']} from {record['s3']['bucket']['name']}"
        )
        log.error(err)
        return False


def put_file(file):

    if environ.get("AWS_LOCALSTACK", False):
        client = get_session().resource("s3", endpoint_url="http://localstack:4566")
    else:
        client = get_session().resource("s3")

    bucket = environ.get("FILE_QUEUE_BUCKET", None)

    try:
        key = f"{file.filename}_{str(uuid4())}"
        obj = client.Object(bucket, key)
        file.file.seek(0)
        obj.put(Body=file.file.read())
        return f"s3://{bucket}/{key}"
    except Exception as err:
        log.error(f"Error uploading {file.filename} to s3")
        log.error(err)
        return None
