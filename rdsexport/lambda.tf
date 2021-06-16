# assume role
resource "aws_iam_role" "rds_export_to_s3_role" {
  name = "${var.function_name}-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Allow",
      "Principal": {"Service": ["lambda.amazonaws.com", "export.rds.amazonaws.com"]},
      "Action": "sts:AssumeRole"
    }
  })
}

# Created Policy for IAM Role (s3 and RDS access)
resource "aws_iam_policy" "rds_export_to_s3_policy" {
  name = "policy"
  policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
            Action : [ "iam:PassRole" ],
            Resource : "*",
            Effect : "Allow"
        },
        {
            Effect : "Allow",
            Action : "rds:*",
            Resource : ["*"]
        },
        {
          Action   = ["s3:*", "kms:*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
  })
}

# Attached IAM Role and the new created Policy
resource "aws_iam_role_policy_attachment" "rds_export_to_s3_polices_attachment" {
  role       = aws_iam_role.rds_export_to_s3_role.name
  policy_arn = aws_iam_policy.rds_export_to_s3_policy.arn
}


resource "aws_kms_key" "rds_export_to_s3_kms_key" {
  description             = "${var.namespace}-${var.stage} KMS key for RDS Export to S3"
  deletion_window_in_days = 30
  enable_key_rotation = true
  tags = {
    Name = "${var.namespace}-${var.stage}-kms-keys"
  }
}


# Created AWS Lamdba Function: Memory Size, Python version, handler, endpoint, doctype and environment settings
resource "aws_lambda_function" "rds_export_to_s3_function" {
  filename         = data.archive_file.rds_export_to_s3_archive.output_path
  source_code_hash = data.archive_file.rds_export_to_s3_archive.output_base64sha256
  function_name    = var.function_name
  description      = "Monthly aws rds snapshot to the S3 bucket for DR needs."
  handler          = "rds_export_to_s3.lambda_handler"
  role             = aws_iam_role.rds_export_to_s3_role.arn
  runtime          = "python3.8"
  memory_size      = 1024
  timeout          = 300

  environment {
    variables = {
      DB_IDENTIFIER = var.db_identifier
      REGION        = var.region
      S3_BUCKET     = "${var.namespace}-${var.stage}-backup"
      KMS_KEY_ID    = aws_kms_key.rds_export_to_s3_kms_key.arn
      IAM_ROLE_ARN  = aws_iam_role.rds_export_to_s3_role.arn
    }
  }
}

data "archive_file" "rds_export_to_s3_archive" {
  type        = "zip"
  output_path = "${path.module}/functions/rds_export_to_s3.zip"
  source_file = "${path.module}/functions/rds_export_to_s3.py"
}
