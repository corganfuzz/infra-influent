"""
EndPoints:
GET  /templates: lists available .pptx templates from SOURCE_BUCKET
POST /modify: replaces tokens in a template and saves to OUTPUT_BUCKET
"""

import io
import json
import os
import re
import boto3
from pptx import Presentation


SOURCE_BUCKET = os.environ["UNTOUCHED_BUCKET"]
OUTPUT_BUCKET = os.environ["PROCESSED_BUCKET"]
AWS_REGION    = os.environ.get("AWS_REGION", "us-east-1")

s3 = boto3.client("s3", region_name=AWS_REGION)


# ---------------------------------------------------------------------------
# S3
# ---------------------------------------------------------------------------

def list_templates(bucket: str) -> list[dict]:
    print(f"Listing templates in bucket: {bucket}")
    response = s3.list_objects_v2(Bucket=bucket)
    contents = response.get("Contents", [])
    print(f"Found {len(contents)} objects in bucket.")
    return [
        {"fileName": obj["Key"], "size": obj["Size"], "lastModified": obj["LastModified"].isoformat()}
        for obj in contents
        if obj["Key"].endswith(".pptx")
    ]


def download_pptx(bucket: str, key: str) -> bytes:
    response = s3.get_object(Bucket=bucket, Key=key)
    return response["Body"].read()


def upload_pptx(bucket: str, key: str, data: bytes) -> None:
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=data,
        ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation",
    )


def build_output_key(original_key: str) -> str:
    return original_key.replace(".pptx", "_modified.pptx")


# ---------------------------------------------------------------------------
# PPTX
# ---------------------------------------------------------------------------

def build_replacer(replacements: dict):
    pattern = re.compile("|".join(re.escape(k) for k in replacements))
    return lambda text: pattern.sub(lambda m: replacements[m.group(0)], text)


def replace_in_paragraph(paragraph, replacer) -> None:
    if not paragraph.runs:
        return

    full_text = "".join(run.text for run in paragraph.runs).strip()
    if not full_text:
        return

    if "{" not in full_text:
        return

    new_text = replacer(full_text)

    if new_text != full_text:
        print(f"Match found! Replacing text: '{full_text}' -> '{new_text}'")
        paragraph.runs[0].text = new_text
        for run in paragraph.runs[1:]:
            run.text = ""


def process_shape(shape, replacer) -> None:
    """Recursively process shapes, groups, and tables."""
    if shape.has_text_frame:
        for paragraph in shape.text_frame.paragraphs:
            replace_in_paragraph(paragraph, replacer)
    
    elif shape.has_table:
        for row in shape.table.rows:
            for cell in row.cells:
                for paragraph in cell.text_frame.paragraphs:
                    replace_in_paragraph(paragraph, replacer)
    
    elif shape.shape_type == 6: # Group shape
        for sub_shape in shape.shapes:
            process_shape(sub_shape, replacer)


def replace_in_presentation(prs: Presentation, replacements: dict) -> None:
    if not replacements:
        return

    replacer = build_replacer(replacements)

    for i, slide in enumerate(prs.slides):
        print(f"Processing slide {i+1}")
        for shape in slide.shapes:
            process_shape(shape, replacer)


def modify_pptx(pptx_bytes: bytes, replacements: dict) -> bytes:
    prs    = Presentation(io.BytesIO(pptx_bytes))
    replace_in_presentation(prs, replacements)
    buffer = io.BytesIO()
    prs.save(buffer)
    buffer.seek(0)
    return buffer.read()


# ---------------------------------------------------------------------------
# Business logic
# ---------------------------------------------------------------------------

def build_replacements(payload: dict) -> dict:
    data = payload["businessData"]
    return {
        "{{PAIN_POINT}}":      data.get("painPoint", ""),
        "{{REVENUE}}":         f"${data.get('revenue', 0):,.0f}",
        "{{ADJUSTED_TARGET}}": f"${round(data.get('revenue', 0) * 0.93):,.0f}",
        "{{TECHNICIANS}}":     str(data.get("technicians", "")),
        "{{REPORTING_DATE}}":  data.get("reportingDate", ""),
    }


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

def validate_modify(payload: dict) -> str | None:
    if not payload.get("template", {}).get("fileName"):
        return "'template.fileName' is required."
    if not payload["template"]["fileName"].endswith(".pptx"):
        return "'template.fileName' must be a .pptx file."
    if "businessData" not in payload:
        return "'businessData' is required."
    required = ["painPoint", "revenue", "technicians", "reportingDate"]
    missing  = [f for f in required if f not in payload["businessData"]]
    if missing:
        return f"Missing fields in businessData: {', '.join(missing)}."
    return None


# ---------------------------------------------------------------------------
# Route handlers
# ---------------------------------------------------------------------------

def handle_list_templates() -> dict:
    try:
        templates = list_templates(SOURCE_BUCKET)
        return success(templates)
    except Exception as e:
        return error(500, str(e))


def handle_modify_pptx(payload: dict) -> dict:
    validation_error = validate_modify(payload)
    if validation_error:
        return error(400, validation_error)

    file_name    = payload["template"]["fileName"]
    replacements = build_replacements(payload)

    try:
        pptx_bytes = download_pptx(SOURCE_BUCKET, file_name)
        modified   = modify_pptx(pptx_bytes, replacements)
        output_key = build_output_key(file_name)

        upload_pptx(OUTPUT_BUCKET, output_key, modified)

        return success({"outputKey": output_key})

    except s3.exceptions.NoSuchKey:
        return error(404, f"Template '{file_name}' not found.")
    except Exception as e:
        return error(500, str(e))


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------

def success(data) -> dict:
    return {
        "statusCode": 200,
        "headers":    {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body":       json.dumps(data),
    }


def error(status_code: int, message: str) -> dict:
    return {
        "statusCode": status_code,
        "headers":    {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body":       json.dumps({"error": message}),
    }


# ---------------------------------------------------------------------------
# Router
# ---------------------------------------------------------------------------

def lambda_handler(event, context):
    path   = event.get("path", "")
    method = event.get("httpMethod", "")
    
    # Normalize path by removing the stage if it's there, but standard proxy+ usually 
    # gives the path matched. The handler expects routes like "GET /templates".
    # We'll just strip trailing slashes and ensure a leading slash.
    path = "/" + path.strip("/")
    route = f"{method} {path}"
    
    body    = event.get("body", "{}")
    payload = json.loads(body) if isinstance(body, str) else body

    if route == "GET /templates":
        return handle_list_templates()

    if route == "POST /modify":
        return handle_modify_pptx(payload)

    return error(404, f"Unknown route: {route}")
