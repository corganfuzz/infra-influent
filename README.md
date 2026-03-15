# Influent: A Unified React-SharePoint Architecture for PPTX Synthesis

This repository contains the serverless infrastructure and orchestration logic for Influent, a system designed to bridge modern React application patterns with SharePoint's enterprise environment.

## Architectural Integration

Influent creates a symbiotic relationship between an AWS-backed Python synthesis engine and custom SharePoint frontends. By decoupling the XML-based PPTX modification from the document rendering layer, the system achieves enterprise-grade stability without the overhead of traditional server-side rendering.

### Infrastructure Components
- **Runtime**: Python 3.13 Lambda with FastAPI and Mangum integration.
- **Synthesis Engine**: Low-level XML manipulation via `python-pptx` to ensure structural integrity during attribute injection.
- **Security Primitives**:
    - **Tier 1**: API Key authentication for administrative endpoints (`/templates`, `/modify`).
    - **Tier 2**: HMAC-SHA256 signed JWTs for secure, time-bound preview access.
- **Configuration**: Managed via Terraform HCL for reproducible VPC, Lambda, and API Gateway deployments.

## The Secure 302-Found Redirection Model

To bypass the binary serialization limitations of standard API Gateways, Influent utilizes a secure redirection pattern for document previews:

1. **Authorization**: The `/preview` endpoint validates the metadata and signature of the provided JWT.
2. **Presigning**: A short-lived (5-minute) S3 GET URL is generated programmatically.
3. **Handover**: The system issues a `302 Found` response.
4. **Acquisition**: Microsoft's Office Online WOPI proxy consumes the presigned stream directly from S3, ensuring zero-latency delivery and bypassing edge-encoding bottlenecks.

## Operational CLI

### Deployment
```bash
terraform -chdir=env/dev apply -auto-approve
```

### Secret Retrieval
```bash
aws apigateway get-api-keys --name-query xpert-dev-api-key --include-values
```

## Module Directory
- **`pptx_utils.py`**: XML transformation logic for dynamic content injection.
- **`token_utils.py`**: Cryptographic signing and verification using secrets stored in AWS SSM Parameter Store.
- **`s3.py`**: High-level S3 client abstractions for synthesis and presigning.
