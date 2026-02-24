resource "aws_s3_bucket" "data_layers" {
  for_each = var.s3_buckets
  bucket   = "${var.project_name}-${var.environment}-${each.key}-data-${data.aws_caller_identity.current.account_id}"

  force_destroy = var.environment == "dev" ? true : false
}

resource "aws_s3_bucket_versioning" "data_layers" {
  for_each = var.s3_buckets
  bucket   = aws_s3_bucket.data_layers[each.key].id
  versioning_configuration {
    status = each.value.versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_layers" {
  for_each = aws_s3_bucket.data_layers
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_layers" {
  for_each = aws_s3_bucket.data_layers
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}
