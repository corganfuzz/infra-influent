output "s3_buckets" {
  value = module.storage.bucket_names
}

output "iam_roles" {
  value = module.iam.role_arns
}

output "api_url" {
  description = "The Invoke URL for the API Gateway"
  value       = module.api_gateway["pptx-modifier"].api_url
}
