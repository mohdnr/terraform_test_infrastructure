import errno
import datetime
import os
import os.path

AV_DEFINITION_S3_BUCKET = os.getenv("AV_DEFINITION_S3_BUCKET")
AV_DEFINITION_S3_PREFIX = os.getenv("AV_DEFINITION_S3_PREFIX", "clamav_defs")
AV_DEFINITION_PATH = os.getenv("AV_DEFINITION_PATH", "/clamav")
AV_SCAN_USE_CACHE = os.environ.get("AV_SCAN_USE_CACHE", True)
AV_WRITE_PATH = os.getenv(
    "AV_WRITE_PATH",
    "/tmp/clamav",  # nosec - [B108:hardcoded_tmp_directory] Lambda only allows write to /tmp
)
AV_SCAN_START_SNS_ARN = os.getenv("AV_SCAN_START_SNS_ARN")
AV_SCAN_START_METADATA = os.getenv("AV_SCAN_START_METADATA", "av-scan-start")
AV_SIGNATURE_METADATA = os.getenv("AV_SIGNATURE_METADATA", "av-signature")
AV_SIGNATURE_OK = "OK"
AV_SIGNATURE_UNKNOWN = "UNKNOWN"
AV_STATUS_CLEAN = os.getenv("AV_STATUS_CLEAN", "clean")
AV_STATUS_INFECTED = os.getenv("AV_STATUS_INFECTED", "infected")
AV_STATUS_METADATA = os.getenv("AV_STATUS_METADATA", "av-status")
AV_STATUS_SNS_ARN = os.getenv("AV_STATUS_SNS_ARN")
AV_STATUS_SNS_PUBLISH_CLEAN = os.getenv("AV_STATUS_SNS_PUBLISH_CLEAN", "True")
AV_STATUS_SNS_PUBLISH_INFECTED = os.getenv("AV_STATUS_SNS_PUBLISH_INFECTED", "True")
AV_TIMESTAMP_METADATA = os.getenv("AV_TIMESTAMP_METADATA", "av-timestamp")
CLAMAVLIB_PATH = os.getenv("CLAMAVLIB_PATH", "./bin")
CLAMSCAN_PATH = os.getenv("CLAMSCAN_PATH", "./bin/clamdscan")
FRESHCLAM_PATH = os.getenv("FRESHCLAM_PATH", "./bin/freshclam")
AV_PROCESS_ORIGINAL_VERSION_ONLY = os.getenv(
    "AV_PROCESS_ORIGINAL_VERSION_ONLY", "False"
)
AV_DELETE_INFECTED_FILES = os.getenv("AV_DELETE_INFECTED_FILES", "False")

AV_DEFINITION_FILE_PREFIXES = ["main", "daily", "bytecode"]
AV_DEFINITION_FILE_SUFFIXES = ["cld", "cvd"]
SNS_ENDPOINT = os.getenv("SNS_ENDPOINT", None)
S3_ENDPOINT = os.getenv("S3_ENDPOINT", None)
LAMBDA_ENDPOINT = os.getenv("LAMBDA_ENDPOINT", None)
IS_LOCALSTACK = os.environ.get("AWS_LOCALSTACK", False)
AWS_ENDPOINT_URL = "http://localstack:4566" if IS_LOCALSTACK else None
AWS_ROLE_TO_ASSUME = os.getenv("AWS_ROLE_TO_ASSUME", "ScanFilesGetObjects")
CLAMAV_LAMBDA_SCAN_TASK_NAME = os.getenv(
    "CLAMAV_LAMBDA_SCAN_TASK_NAME", "clamav_scan_s3"
)


def create_dir(path):
    if not os.path.exists(path):
        try:
            print("Attempting to create directory %s.\n" % path)
            os.makedirs(path)
        except OSError as exc:
            print("Error %s creating directory %s.\n" % (str(exc), path))
            if exc.errno != errno.EEXIST:
                raise


def get_timestamp():
    return datetime.datetime.utcnow().strftime("%Y/%m/%d %H:%M:%S UTC")
