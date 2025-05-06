resource "aws_config_configuration_recorder" "main" {
  name     = "config-recorder-${var.project}"
  role_arn = module.iam-role-config.iam_role_arn
  #role_arn = aws_iam_role.r.arn

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
}

resource "aws_config_retention_configuration" "main" {
  retention_period_in_days = 90
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
}