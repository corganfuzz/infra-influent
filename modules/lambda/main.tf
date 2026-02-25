data "archive_file" "zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.terraform/lambda_builds/${var.function_name}.zip"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.zip.output_path
  function_name    = "${var.project_name}-${var.environment}-${var.function_name}"
  role             = var.lambda_role_arn
  handler          = var.lambda_config.handler
  runtime          = var.lambda_config.runtime
  timeout          = var.lambda_config.timeout
  memory_size      = var.lambda_config.memory_size
  source_code_hash = data.archive_file.zip.output_base64sha256

  environment {
    variables = var.environment_variables
  }
}
