variable "project_name" { type = string }
variable "environment" { type = string }
variable "lambda_invoke_arn" { type = string }
variable "lambda_function_name" { type = string }

variable "cors_allowed_origins" {
  description = "List of allowed CORS origins for the API Gateway"
  type        = list(string)
  default     = ["*"]
}
