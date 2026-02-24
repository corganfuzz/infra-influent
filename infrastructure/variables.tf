variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }

variable "s3_buckets" {
  description = "Map of S3 bucket configurations"
  type = map(object({
    versioning = bool
  }))
}

variable "iam_roles" {
  description = "Map of IAM role configurations"
  type = map(object({
    trust_service = string
  }))
}

variable "lambdas" {
  description = "Map of Lambda function configurations"
  type        = any
}

variable "api_gateways" {
  description = "Map of API Gateway configurations"
  type        = any
}
