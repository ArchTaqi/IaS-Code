resource "aws_cloudwatch_log_group" "rds_export_to_s3" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.cloudwatch_expire_days
}

data "aws_iam_policy_document" "rds_export_to_s3_log_policy" {
  statement {
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.rds_export_to_s3.arn}:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

resource "aws_iam_policy" "rds_export_to_s3_log_policy" {
  name   = "${var.function_name}-cloudwatch-policy"
  policy = data.aws_iam_policy_document.rds_export_to_s3_log_policy.json
}

resource "aws_iam_role_policy_attachment" "rds_export_to_s3" {
  role       = aws_iam_role.rds_export_to_s3_role.name
  policy_arn = aws_iam_policy.rds_export_to_s3_log_policy.arn
}

//permission
resource "aws_lambda_permission" "allow_cloudwatch_invocation" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_export_to_s3_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_export_to_s3_rule.arn
}

// event
resource "aws_cloudwatch_event_rule" "rds_export_to_s3_rule" {
  name        = "rds_export_to_s3"
  description = "Triggers a lambda function that export an rds snapshots to s3 for DR."
  schedule_expression =  var.schedule_expression
}

// target
resource "aws_cloudwatch_event_target" "rds_export_to_s3_target" {
  rule = aws_cloudwatch_event_rule.rds_export_to_s3_rule.name
  arn  = aws_lambda_function.rds_export_to_s3_function.arn
}
