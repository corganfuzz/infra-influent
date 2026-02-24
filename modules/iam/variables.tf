variable "project_name" { type = string }
variable "environment" { type = string }
variable "storage_bucket_arns" {
  type        = map(string)
  description = "Map of S3 bucket ARNs from storage module"
}

variable "iam_roles" {
  type = map(object({
    trust_service = string
  }))
}
