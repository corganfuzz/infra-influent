variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }
variable "lambda_role_arn" { type = string }
variable "lambda_config" { type = any }
variable "function_name" { type = string }
variable "source_dir" { type = string }
variable "environment_variables" {
  type    = map(string)
  default = {}
}
