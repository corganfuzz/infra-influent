import os
import boto3
from typing import Generator


s3 = boto3.client(
    "s3",
    region_name=os.environ.get("AWS_REGION", "us-east-1"),
    endpoint_url=os.environ.get("S3_ENDPOINT_URL", None),
)

SOURCE_BUCKET = os.environ["UNTOUCHED_BUCKET"]
OUTPUT_BUCKET = os.environ["PROCESSED_BUCKET"]


def list_templates() -> list[dict]:
    response = s3.list_objects_v2(Bucket=SOURCE_BUCKET)
    return [
        {
            "fileName":    obj["Key"],
            "size":        obj["Size"],
            "lastModified": obj["LastModified"].isoformat(),
        }
        for obj in response.get("Contents", [])
        if obj["Key"].endswith(".pptx")
    ]


def download_pptx(key: str) -> bytes:
    return s3.get_object(Bucket=SOURCE_BUCKET, Key=key)["Body"].read()

def stream_pptx(key: str) -> Generator[bytes, None, None]:
    response = s3.get_object(Bucket=SOURCE_BUCKET, Key=key)
    yield from response["Body"].iter_chunks(chunk_size=65536)


def upload_pptx(key: str, data: bytes) -> None:
    s3.put_object(
        Bucket=OUTPUT_BUCKET,
        Key=key,
        Body=data,
        ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation",
    )


def build_output_key(original_key: str) -> str:
    return original_key.replace(".pptx", "_modified.pptx")


def file_exists(key: str) -> bool:
    from botocore.exceptions import ClientError
    try:
        s3.head_object(Bucket=OUTPUT_BUCKET, Key=key)
        return True
    except ClientError:
        return False


def presigned_url(key: str, expiration: int = 3600) -> str:
    return s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": OUTPUT_BUCKET, "Key": key},
        ExpiresIn=expiration,
    )