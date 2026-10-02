resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  repo_root     = "${path.module}/.."
  api_zip_path  = "${local.repo_root}/build/distributions/anitracker-1.0.0.zip"
  frontend_dist = "${local.repo_root}/frontend/dist"

  api_zip_key = "api/anitracker.zip"
  schema_key  = "sql/schema.sql"
  seed_key    = "sql/seed_data.sql"

  content_types = {
    html  = "text/html"
    js    = "application/javascript"
    css   = "text/css"
    json  = "application/json"
    map   = "application/json"
    ico   = "image/x-icon"
    svg   = "image/svg+xml"
    png   = "image/png"
    jpg   = "image/jpeg"
    jpeg  = "image/jpeg"
    gif   = "image/gif"
    webp  = "image/webp"
    woff  = "font/woff"
    woff2 = "font/woff2"
    txt   = "text/plain"
  }
}

# ---------- Artifacts bucket (API build + SQL), read by the EC2 instance via LabInstanceProfile ----------

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project_name}-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "api_zip" {
  bucket = aws_s3_bucket.artifacts.id
  key    = local.api_zip_key
  source = local.api_zip_path
  etag   = filemd5(local.api_zip_path)
}

resource "aws_s3_object" "schema" {
  bucket = aws_s3_bucket.artifacts.id
  key    = local.schema_key
  source = "${local.repo_root}/schema.sql"
  etag   = filemd5("${local.repo_root}/schema.sql")
}

resource "aws_s3_object" "seed" {
  bucket = aws_s3_bucket.artifacts.id
  key    = local.seed_key
  source = "${local.repo_root}/seed_data.sql"
  etag   = filemd5("${local.repo_root}/seed_data.sql")
}

# ---------- Frontend bucket (built Vue app), private and served only through CloudFront ----------

resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project_name}-frontend-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "frontend" {
  for_each = fileset(local.frontend_dist, "**")

  bucket       = aws_s3_bucket.frontend.id
  key          = each.value
  source       = "${local.frontend_dist}/${each.value}"
  etag         = filemd5("${local.frontend_dist}/${each.value}")
  content_type = lookup(local.content_types, lower(try(regex("\\.([^.]+)$", each.value)[0], "")), "application/octet-stream")
  # index.html must always be revalidated; hashed assets under assets/ can be cached long-term.
  cache_control = each.value == "index.html" ? "no-cache" : "public, max-age=31536000, immutable"
}

data "aws_iam_policy_document" "frontend" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend.json

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}
