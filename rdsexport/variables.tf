variable "region" {
  type        = string
}

variable "namespace" {
  type        = string
}

variable "stage" {
  description = "The stage e.g. dev, stage, prod"
  default     = "default"
}

variable "function_name" {
  type = string
  default = "export_to_s3"
  description = "The name for the RDS export to S3 lambda function."
}

variable "db_identifier" {
  description = "The database identifier"
  type        = string
}

variable "iam_role" {
  type = string
}

variable "schedule_expression" {
  type = string
  description = "Cron expression for start RDS export to S3"
}

variable "environment_variables" {
  default     = {}
  description = "Variables"
  type        = map(string)
}

variable "cloudwatch_expire_days" {
  description = "Expiration period for CloudWatch log events."
  type        = number
  default     = 30
}

variable "lambda_log_level" {
  description = "Log level for the Lambda Python runtime."
  default     = "DEBUG"
}
