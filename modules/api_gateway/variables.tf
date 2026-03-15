variable "project_name" { type = string }
variable "environment" { type = string }
variable "lambda_invoke_arn" { type = string }
variable "lambda_function_name" { type = string }

variable "cors_allowed_origins" {
  description = "List of allowed CORS origins for the API Gateway"
  type        = list(string)
  default     = ["*"]
}

variable "frontend_env_path" {
  description = "Optional path to the frontend .env.local file for automatic synchronization"
  type        = string
  default     = null
}
