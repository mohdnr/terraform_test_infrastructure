import os

from boto3wrapper.wrapper import get_session

from clamav_scanner import clamav

from .common import AWS_ENDPOINT_URL
from .common import AV_WRITE_PATH
from .common import AV_DEFINITION_S3_BUCKET
from .common import AV_DEFINITION_S3_PREFIX
from .common import CLAMAVLIB_PATH
from .common import get_timestamp


def update_virus_defs():
    s3 = get_session().resource("s3", endpoint_url=AWS_ENDPOINT_URL)
    s3_client = get_session().client("s3", endpoint_url=AWS_ENDPOINT_URL)

    print("ClamAV virus definition update starting at %s\n" % (get_timestamp()))
    to_download = clamav.update_defs_from_s3(
        s3_client, AV_DEFINITION_S3_BUCKET, AV_DEFINITION_S3_PREFIX
    )

    for download in to_download.values():
        s3_path = download["s3_path"]
        local_path = download["local_path"]
        print("Downloading definition file %s from s3://%s" % (local_path, s3_path))
        s3.Bucket(AV_DEFINITION_S3_BUCKET).download_file(s3_path, local_path)
        print("Downloading definition file %s complete!" % (local_path))

    clamav.update_defs_from_freshclam(AV_WRITE_PATH, CLAMAVLIB_PATH)
    # If main.cvd gets updated (very rare), we will need to force freshclam
    # to download the compressed version to keep file sizes down.
    # The existence of main.cud is the trigger to know this has happened.
    if os.path.exists(os.path.join(AV_WRITE_PATH, "main.cud")):
        os.remove(os.path.join(AV_WRITE_PATH, "main.cud"))
        if os.path.exists(os.path.join(AV_WRITE_PATH, "main.cvd")):
            os.remove(os.path.join(AV_WRITE_PATH, "main.cvd"))
        clamav.update_defs_from_freshclam(AV_WRITE_PATH, CLAMAVLIB_PATH)
    clamav.upload_defs_to_s3(
        s3_client, AV_DEFINITION_S3_BUCKET, AV_DEFINITION_S3_PREFIX, AV_WRITE_PATH
    )
    print("ClamAV virus definition update finished at %s\n" % get_timestamp())
