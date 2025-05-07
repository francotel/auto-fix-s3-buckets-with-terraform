data "aws_iam_policy_document" "config-bucket-policy" {
  statement {
    sid     = "AWSConfigBucketPermissionsCheck"
    actions = ["s3:GetBucketAcl"]
    resources = [
      "arn:aws:s3:::s3-bucket-config-logs"
    ]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid     = "AWSConfigBucketDelivery"
    actions = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = [
      "arn:aws:s3:::s3-bucket-config-logs/AWSLogs/${local.aws-account-id}/Config/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.4.0"

  bucket                   = "s3-bucket-config-logs"
  control_object_ownership = true
  force_destroy            = var.s3-force-destroy
  attach_policy            = true
  policy                   = data.aws_iam_policy_document.config-bucket-policy.json

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}