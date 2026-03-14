output "preview_token_secret" {
  description = "Plaintext preview token secret for Lambda environment"
  value       = data.aws_ssm_parameter.preview_token_secret.value
  sensitive   = true
}
