output "api_url" {
  description = "The Invoke URL for the API Gateway"
  value       = module.infrastructure.api_url
}

output "api_key" {
  description = "The API key for the API Gateway"
  value       = module.infrastructure.api_key
  sensitive   = true
}
