
# Example: fine-grained access for this region's resources
data "aws_iam_policy_document" "lambda_regional" {
  statement {
    sid       = "SQSReceive"
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ChangeMessageVisibility"]
    resources = [var.sqs_fifo_arn] # from your SQS module in this stack
  }

  statement {
    sid       = "DDBIdempotency"
    actions   = ["dynamodb:PutItem", "dynamodb:GetItem"]
    resources = [var.dynamodb_idemp_arn] # from your DDB module in this stack
  }

  statement {
    sid       = "S3Remediate"
    actions   = ["s3:GetObjectAcl", "s3:PutObjectAcl", "s3:GetObjectTagging", "s3:PutObjectTagging"]
    resources = ["arn:aws:s3:::*/*"] # scope to bucket(s)
  }
}

resource "aws_iam_policy" "lambda_regional" {
  name   = "s3-remediator-exec-regional"
  policy = data.aws_iam_policy_document.lambda_regional.json
}

resource "aws_iam_role_policy_attachment" "lambda_regional_attach" {
  role       = var.lambda_exec_role_name
  policy_arn = aws_iam_policy.lambda_regional.arn
}
