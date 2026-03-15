import logging
import json
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException, Query, Response
from fastapi.responses import RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum
from token_utils import mint_token, verify_token

import s3
import pptx_utils as pptx_lib
from models import ModifyRequest

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https://.*\.sharepoint\.com",
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "X-Api-Key"],
)

@app.get("/templates")
def get_templates():
    logger.info("Listing templates")
    templates = s3.list_templates()

    for template in templates:
        template["token"] = mint_token(template["fileName"])

    return Response(content=json.dumps(templates), media_type="application/json")

@app.post("/modify")
def post_modify(request: ModifyRequest):
    file_name = request.template.fileName
    replacements = pptx_lib.build_replacements(request.businessData)

    try:
        pptx_bytes = s3.download_pptx(file_name)
        modified = pptx_lib.modify_pptx(pptx_bytes, replacements)
        output_key = s3.build_output_key(file_name)

        s3.upload_pptx(output_key, modified)
        logger.info(f"Modified PPTX uploaded: {output_key}")

        return Response(
            content=json.dumps({"outputKey": output_key}), media_type="application/json"
        )

    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchKey":
            raise HTTPException(
                status_code=404, detail=f"Template '{file_name}' not found."
            )
        raise


@app.get("/download")
def get_download(fileName: str = Query(...)):
    if not s3.file_exists(fileName):
        logger.warning(f"File not found: {fileName}")
        raise HTTPException(status_code=404, detail=f"File '{fileName}' not found.")

    data = {"downloadUrl": s3.presigned_url(fileName)}
    return Response(content=json.dumps(data), media_type="application/json")


@app.api_route("/preview", methods=["GET", "HEAD"])
def get_preview(token: str = Query(...)):
    file_name = verify_token(token)

    logger.info(f"Previewing PPTX: {file_name}")

    try:
        presigned = s3.source_presigned_url(file_name, expiration=300)
        return RedirectResponse(url=presigned)
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchKey":
            raise HTTPException(
                status_code=404, detail=f"File '{file_name}' not found."
            )
        raise


lambda_handler = Mangum(app, lifespan="off")
