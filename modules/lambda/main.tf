resource "null_resource" "install_dependencies" {
  triggers = {
    handler_hash      = filemd5("${var.source_dir}/handler.py")
    requirements_hash = filemd5("${var.source_dir}/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<EOT
      rm -rf /tmp/${var.function_name}_build
      mkdir -p /tmp/${var.function_name}_build

      # copy only your source files
      cp ${var.source_dir}/handler.py /tmp/${var.function_name}_build/
      cp ${var.source_dir}/requirements.txt /tmp/${var.function_name}_build/

      # install deps into the temp dir, pinned to python 3.13 for Lambda
      # force linux platform wheels for C-extensions (like lxml) using pip
      python3 -m pip install \
        --target /tmp/${var.function_name}_build \
        --platform manylinux2014_x86_64 \
        --implementation cp \
        --python-version 3.13 \
        --only-binary=:all: \
        --upgrade \
        -r ${var.source_dir}/requirements.txt \
        --quiet
    EOT
  }
}

data "archive_file" "zip" {
  depends_on  = [null_resource.install_dependencies]
  type        = "zip"
  source_dir  = "/tmp/${var.function_name}_build"
  output_path = "${path.root}/.terraform/lambda_builds/${var.function_name}.zip"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 7
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
