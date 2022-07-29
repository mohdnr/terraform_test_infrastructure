from fastapi import (
    FastAPI,
    APIRouter,
    Body,
    Depends,
    File,
    Response,
    status,
    UploadFile,
)
from uuid import uuid4

from clamav_scanner.common import AV_WRITE_PATH, create_dir
from clamav_scanner.scan import launch_scan
from clamav_scanner.update import update_virus_defs
from models.Scan import Scan

app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.get("/clamav/update")
def update_av_defs():
    result = update_virus_defs()
    return {"Status": result}

@app.post("/clamav")
def start_clamav_scan(
    response: Response,
    file: UploadFile = File(...),
):
    try:
        save_path = f"{AV_WRITE_PATH}/quarantine/{str(uuid4())}"
        create_dir(f"{AV_WRITE_PATH}/quarantine")
        with open(save_path, "wb") as file_on_disk:
            file.file.seek(0)
            file_on_disk.write(file.file.read())
        scan = Scan()
        scan_verdict = launch_scan(save_path, scan.id)
        return {"status": "completed", "verdict": scan_verdict}
    except Exception as err:
        print(err)
        response.status_code = status.HTTP_502_BAD_GATEWAY
        return {"error": f"error scanning file [{file.filename}] with clamav"}
