locals {
  # ==============================================
  # Project Settings
  # ==============================================
  project_name = "xpert"
  environment  = "staging"
  aws_region   = "us-east-1"

  # ==============================================
  # Storage Configuration
  # ==============================================
  s3_buckets = {
    "untoched-pptx"  = { versioning = true }
    "processed-pptx" = { versioning = true }
  }

  # ==============================================
  # IAM Roles and Permissions
  # ==============================================
  iam_roles = {
    "pptx-modifier" = { trust_service = "lambda.amazonaws.com" }
  }

  # ==============================================
  # AWS Lambda Configuration
  # ==============================================
  lambdas = {
    "pptx-modifier" = {
      runtime     = "python3.11"
      handler     = "handler.lambda_handler"
      timeout     = 60
      memory_size = 512
      source_dir  = "src_pptx_modifier"
      role_key    = "pptx-modifier"
      env_vars = {
        UNTOUCHED_BUCKET = "untoched-pptx"
        PROCESSED_BUCKET = "processed-pptx"
      }
    }
  }

  api_gateways = {
    "pptx-modifier" = {
      lambda_key = "pptx-modifier"
    }
  }
}
