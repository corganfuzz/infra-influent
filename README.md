# PPTX Cloud Converter

This repository contains the Terraform infrastructure and backend code for the Xpert PPTX Modifier application.

## Endpoints

The FastAPI application exposes the following endpoints via AWS API Gateway:

- `GET /templates` - Lists all available PPTX templates.
- `POST /modify` - Modifies a specified PPTX template with the provided business data.
- `GET /download` - Generates a presigned URL to download a modified PPTX file (requires `fileName` query parameter).

## Retrieving Secrets & URLs

To interact with the deployed API, you can retrieve your active API Key and API Gateway URL using the AWS CLI or Terraform.

### 1. Retrieve the API Key
Use the following AWS CLI command to fetch the API Gateway key value:
```bash
aws apigateway get-api-keys --name-query xpert-dev-api-key --include-values
```

### 2. Retrieve the API URL
The easiest way to get the base API URL is via Terraform outputs:
```bash
terraform -chdir=env/dev output -raw api_url
```

Alternatively, using pure AWS CLI:
```bash
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='xpert-dev-api'].id" --output text)
echo "https://${API_ID}.execute-api.us-east-1.amazonaws.com/dev"
```
