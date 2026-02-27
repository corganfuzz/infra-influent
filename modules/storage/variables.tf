variable "project_name" { type = string }
variable "environment" { type = string }
variable "s3_buckets" {
  type = map(object({
    versioning = bool
  }))
}
variable "templates_dir" {
  type        = string
  description = "Path to the directory containing PPTX templates to upload"
  default     = ""
}
