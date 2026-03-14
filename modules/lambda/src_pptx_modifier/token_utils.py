import os
import time
import jwt
from fastapi import HTTPException

SECRET = os.getenv("PREVIEW_TOKEN_SECRET")
TTL_SECONDS = 300

if not SECRET:
    raise ValueError("PREVIEW_TOKEN_SECRET environment variable is not set")

def mint_token(file_name: str) -> dict:
    try:
        return jwt.encode(
            {"key": file_name, "exp": time.time() + TTL_SECONDS},
            SECRET,
            algorithm="HS256"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def verify_token(token: str) -> str:
    try:
        payload = jwt.decode(token, SECRET, algorithms=["HS256"])
        return payload["key"]
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
    