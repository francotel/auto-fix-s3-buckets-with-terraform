resource "aws_s3_bucket" "vulnerable-demo-bucket" {
  bucket = "vulnerable-demo-bucket-${var.project}-${random_string.suffix.result}"
  tags = merge({
    Purpose = "Security Demo"
  })
}

resource "aws_s3_bucket_public_access_block" "disable-protection" {
  bucket = aws_s3_bucket.vulnerable-demo-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "public-read" {
  bucket = aws_s3_bucket.vulnerable-demo-bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.vulnerable-demo-bucket.arn}/*"
      }
    ]
  })
}

# resource "aws_s3_bucket_server_side_encryption_configuration" "none" {}

resource "aws_s3_bucket_versioning" "disabled" {
  bucket = aws_s3_bucket.vulnerable-demo-bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

output "vulnerable_bucket_name" {
  value       = aws_s3_bucket.vulnerable-demo-bucket.id
  description = "Name S3 demo with vulnerables"
}