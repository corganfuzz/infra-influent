output "api_url" {
  value = aws_api_gateway_stage.this.invoke_url
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.this.execution_arn
}

output "api_key" {
  description = "The API key value for the X-Api-Key header"
  value       = aws_api_gateway_api_key.this.value
  sensitive   = true
}
