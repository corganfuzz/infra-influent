resource "random_password" "preview_token_secret" {
  length  = 64
  special = false
  upper   = false
}

resource "aws_ssm_parameter" "preview_token_secret" {
  name        = "/${var.project_name}/${var.environment}/preview-token-secret"
  description = "HMAC-SHA256 signing secret for PPTX preview tokens"
  type        = "SecureString"
  value       = random_password.preview_token_secret.result
}

data "aws_ssm_parameter" "preview_token_secret" {
  name            = aws_ssm_parameter.preview_token_secret.name
  with_decryption = true
  depends_on      = [aws_ssm_parameter.preview_token_secret]
}
