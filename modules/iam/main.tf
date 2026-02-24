data "aws_caller_identity" "current" {}

# Generic Role Creation
resource "aws_iam_role" "this" {
  for_each = var.iam_roles
  name     = "${var.project_name}-${var.environment}-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = each.value.trust_service == "self" ? {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          } : length(regexall("\\.amazonaws\\.com$", each.value.trust_service)) > 0 ? {
          Service = each.value.trust_service
          } : {
          AWS = each.value.trust_service
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  for_each   = { for k, v in var.iam_roles : k => v if v.trust_service == "lambda.amazonaws.com" }
  role       = aws_iam_role.this[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "s3_access" {
  for_each = { for k, v in var.iam_roles : k => v if v.trust_service == "lambda.amazonaws.com" }
  name     = "S3Access"
  role     = aws_iam_role.this[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          for arn in values(var.storage_bucket_arns) : arn
        ]
      },
      {
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          for arn in values(var.storage_bucket_arns) : "${arn}/*"
        ]
      }
    ]
  })
}
