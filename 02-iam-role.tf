module "iam-role-config" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "v5.55.0"

  trusted_role_services = [
    "config.amazonaws.com"
  ]

  create_role                     = true
  role_name                       = "iam-role-config-${var.project}"
  create_custom_role_trust_policy = true
  custom_role_trust_policy        = data.aws_iam_policy_document.custom_trust_policy.json
  custom_role_policy_arns         = ["arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"]

}

data "aws_iam_policy_document" "custom_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "allow-s3-config-delivery" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetBucketAcl"
    ]

    resources = [
      "arn:aws:s3:::s3-bucket-config-logs",
      "arn:aws:s3:::s3-bucket-config-logs/*"
    ]
  }
}

resource "aws_iam_role_policy" "s3-config-delivery-policy" {
  name   = "AllowS3ConfigDelivery"
  role   = module.iam-role-config.iam_role_name
  policy = data.aws_iam_policy_document.allow-s3-config-delivery.json
}
