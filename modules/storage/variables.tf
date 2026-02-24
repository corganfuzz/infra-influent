variable "project_name" { type = string }
variable "environment" { type = string }
variable "s3_buckets" {
  type = map(object({
    versioning = bool
  }))
}
