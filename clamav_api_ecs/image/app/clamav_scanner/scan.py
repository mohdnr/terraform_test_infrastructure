import datetime
import json
import os

from .common import AV_DEFINITION_S3_BUCKET
from .common import AV_DEFINITION_S3_PREFIX
from .common import AV_SIGNATURE_METADATA
from .common import AV_STATUS_METADATA
from .common import AV_TIMESTAMP_METADATA
from .common import AWS_ENDPOINT_URL
from .common import AV_SIGNATURE_UNKNOWN
from .common import CLAMAV_LAMBDA_SCAN_TASK_NAME

from boto3wrapper.wrapper import get_session
from clamav_scanner.clamav import determine_verdict, update_defs_from_s3, scan_file
from logger import log
from models.Scan import Scan, ScanProviders, ScanVerdicts


def launch_scan(file_path, scan_id, aws_account=None, session=None, sns_arn=None):
    verdict = ""
    s3 = get_session().resource("s3", endpoint_url=AWS_ENDPOINT_URL)
    s3_client = get_session().client("s3", endpoint_url=AWS_ENDPOINT_URL)

    to_download = update_defs_from_s3(
        s3_client, AV_DEFINITION_S3_BUCKET, AV_DEFINITION_S3_PREFIX
    )

    for download in to_download.values():
        s3_path = download["s3_path"]
        local_path = download["local_path"]
        log.info("Downloading definition file %s from s3://%s" % (local_path, s3_path))
        s3.Bucket(AV_DEFINITION_S3_BUCKET).download_file(s3_path, local_path)
        log.info("Downloading definition file %s complete!" % (local_path))
    try:
        print("started")
        checksum, scan_result, scan_signature, scanned_path = scan_file(
            session, file_path, aws_account
        )
        print("done")

        verdict = determine_verdict(ScanProviders.CLAMAV.value, scan_result)
        log.info("Scan of %s resulted in %s\n" % (file_path, scan_result))

        # Delete downloaded file to free up room on re-usable lambda function container

        try:
          os.remove(scanned_path)
        except OSError:
            pass

    except Exception as err:
        log.error("Scan %s failed. Reason %s" % (scan_id, str(err)))
        verdict = ScanVerdicts.ERROR.value

    return verdict
