from pydantic import BaseModel
from typing import Optional

class Template(BaseModel):
    id:       Optional[str] = None
    fileName: str
    previewToken: Optional[str] = None


class BusinessData(BaseModel):
    painPoint:     str
    revenue:       float
    technicians:   int
    reportingDate: str

class ModifyRequest(BaseModel):
    requestId:    Optional[str] = None
    submittedAt:  Optional[str] = None
    template:     Template
    businessData: BusinessData