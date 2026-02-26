terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

module "storage" {
  source = "../modules/storage"

  project_name = var.project_name
  environment  = var.environment
  s3_buckets   = var.s3_buckets
}

module "iam" {
  source = "../modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  iam_roles           = var.iam_roles
  storage_bucket_arns = module.storage.bucket_arns
}

module "lambda" {
  for_each = var.lambdas
  source   = "../modules/lambda"

  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  lambda_role_arn = module.iam.role_arns[each.value.role_key]
  function_name   = each.key
  source_dir      = "${path.module}/../modules/lambda/${each.value.source_dir}"

  lambda_config = {
    runtime     = each.value.runtime
    handler     = each.value.handler
    timeout     = each.value.timeout
    memory_size = each.value.memory_size
  }

  environment_variables = {
    for k, v in each.value.env_vars : k => module.storage.bucket_names[v]
  }
}

module "api_gateway" {
  for_each = var.api_gateways
  source   = "../modules/api_gateway"

  project_name         = var.project_name
  environment          = var.environment
  lambda_invoke_arn    = module.lambda[each.value.lambda_key].invoke_arn
  lambda_function_name = module.lambda[each.value.lambda_key].function_name
  cors_allowed_origins = try(each.value.cors_allowed_origins, ["*"])
}
