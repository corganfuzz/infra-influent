output "api_url" {
  value = "${aws_api_gateway_stage.this.invoke_url}/chat"
}

output "api_key" {
  value     = aws_api_gateway_api_key.this.value
  sensitive = true
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.this.execution_arn
}
