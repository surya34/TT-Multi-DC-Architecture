data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { 
      type = "Service"
      identifiers = ["lambda.amazonaws.com"] 
    }
  }
}

resource "aws_iam_role" "local_role_name" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
  permissions_boundary = var.permissions_boundary_arn
  tags               = var.tags
}

# Baseline logging + x-ray only (resource-agnostic, safe to keep global)
data "aws_iam_policy_document" "baseline" {
  statement {
    sid     = "LoggingAndTracing"
    actions = [
      "logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents",
      "xray:PutTraceSegments","xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "baseline" {
  name   = "${var.role_name}-baseline"
  policy = data.aws_iam_policy_document.baseline.json
}

resource "aws_iam_role_policy_attachment" "baseline" {
  role       = aws_iam_role.local_role_name.name
  policy_arn = aws_iam_policy.baseline.arn
}

