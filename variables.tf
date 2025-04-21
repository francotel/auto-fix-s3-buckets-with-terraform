# --- Variables ---
variable "env" {
  type        = string
  description = "Environment name"
}

variable "project" {
  description = "Project Name or service"
  type        = string
}

variable "aws-region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "owner" {
  description = "Owner Name or service"
  type        = string
}

variable "cost" {
  description = "Center of cost"
  type        = string
}

variable "tf-version" {
  description = "Terraform version that used for the project"
  type        = string
}

variable "schedule-expression" {
  description = "Cron expression for EventBridge to trigger the Lambda function"
  default     = "rate(12 hours)"
}

variable "parameter-name" {
  description = "Name of the Slack Webhook URL parameter in Parameter Store"
  default     = "/slack/webhook/url"
}

variable "slack-webhook-url" {
  description = "Slack Webhook URL to post Trusted Advisor summaries"
}

variable "email-alert" {
  type = list(string)
}