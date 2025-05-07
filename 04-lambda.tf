data "archive_file" "zip-python-code" {
  type        = "zip"
  source_file = "./src/index.py"
  output_path = "./src/python.zip"
}

module "lambda-s3-fix" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.2"

  function_name = "lambda-config-${var.project}"
  description   = "Lambda function code is deployed separately"
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 128
  timeout       = 15

  environment_variables = {
    REQUIRE_ENCRYPTION          = "true"
    REQUIRE_BLOCK_PUBLIC_ACCESS = "true"
    DRY_RUN                     = "false"
  }

  create_package         = false
  local_existing_package = "./src/python.zip"

  ignore_source_code_hash                 = false
  create_current_version_allowed_triggers = false

  cloudwatch_logs_retention_in_days = 30
  cloudwatch_logs_log_group_class   = "STANDARD"
  cloudwatch_logs_skip_destroy      = false

  allowed_triggers = {
    config = {
      principal    = "config.amazonaws.com"
      statement_id = "AllowExecutionFromConfig"
    }
  }

  attach_policy_statements = true
  policy_statements = {
    config = {
      effect = "Allow",
      actions = [
        "config:PutEvaluations",
        "config:Describe*",
        "config:Get*",
        "config:PutConfigRule"
      ],
      resources = ["*"]
    },
    s3_remediation = {
      effect = "Allow",
      actions = [
        "s3:GetBucket*",
        "s3:PutBucket*",
        "s3:PutEncryptionConfiguration",
        "s3:PutBucketPolicy",
        "s3:ListAllMyBuckets",
        "s3:GetEncryptionConfiguration",
        "s3:GetPublicAccessBlock",
        "s3:PutPublicAccessBlock"
      ],
      resources = ["arn:aws:s3:::*"]
    },
  }

  tags = merge({
    Component = "Security",
    Purpose   = "ConfigRemediation"
  })
}