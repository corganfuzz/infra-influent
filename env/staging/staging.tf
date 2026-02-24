module "infrastructure" {
  source = "../../infrastructure"

  project_name = local.project_name
  environment  = local.environment
  aws_region   = local.aws_region
  s3_buckets   = local.s3_buckets
  iam_roles    = local.iam_roles
  lambdas      = local.lambdas
  api_gateways = local.api_gateways

  providers = {
    aws = aws
  }
}
