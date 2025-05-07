resource "aws_config_configuration_recorder" "main" {
  name     = "config-recorder-${var.project}"
  role_arn = module.iam-role-config.iam_role_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = false
  }
  recording_mode {
    recording_frequency = "CONTINUOUS"
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "config-delivery-${var.project}"
  s3_bucket_name = module.s3-bucket.s3_bucket_id
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_retention_configuration" "main" {
  retention_period_in_days = 90
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_config_rule" "s3-security-rule" {
  name        = "s3-custom-rule-${var.project}"
  description = "Custom rule for S3 security compliance checks"
  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = module.lambda-s3-fix.lambda_function_arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
    compliance_resource_id    = aws_s3_bucket.vulnerable-demo-bucket.id
  }

  input_parameters = jsonencode({
    "requiredEncryption" : true,
    "blockPublicAccess" : true
  })

  depends_on = [
    aws_config_configuration_recorder_status.main
  ]
}