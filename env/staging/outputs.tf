output "iam_roles" {
  value = module.infrastructure.iam_roles
}

output "bedrock_kb_id" {
  value = module.infrastructure.bedrock_kb_id
}

output "bedrock_data_source_id" {
  value = module.infrastructure.bedrock_data_source_id
}

output "api_url" {
  description = "The Invoke URL for the API Gateway"
  value       = module.infrastructure.api_url
}

output "api_key" {
  description = "The API Key for authentication"
  value       = module.infrastructure.api_key
  sensitive   = true
}
