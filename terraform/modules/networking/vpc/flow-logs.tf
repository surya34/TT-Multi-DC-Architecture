# terraform/modules/networking/vpc/flow-logs.tf

/**
 * VPC Flow Logs Configuration
 * 
 * Enables network traffic logging for security and compliance
 */

 resource "aws_kms_key" "flow_logs_kms_key_id" {
  description             = "An  symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 20
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Allow Account Root Full Access"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Sid = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

 }

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  
  name              = "/aws/vpc/${var.name_prefix}"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = aws_kms_key.flow_logs_kms_key_id.arn
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-flow-logs"
    }
  )
  # Add this lifecycle block to ignore tags that are automatically added by AWS.
  lifecycle {
    ignore_changes = [
      tags_all,
    ]
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  
  name = "${var.name_prefix}-flow-logs-role"

  assume_role_policy = jsonencode({
   Version = "2012-10-17"
   Statement = [{
     Action = "sts:AssumeRole"
     Effect = "Allow"
     Principal = {
       Service = "vpc-flow-logs.amazonaws.com"
     }
   }]
 })
 
 tags = merge(
   var.tags,
   {
     Name = "${var.name_prefix}-flow-logs-role"
   }
 )
  # Add this lifecycle block to ignore tags that are automatically added by AWS.
  lifecycle {
    ignore_changes = [
      tags_all,
    ]
  }
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_logs" {
 count = var.enable_flow_logs ? 1 : 0
 
 name = "${var.name_prefix}-flow-logs-policy"
 role = aws_iam_role.flow_logs[0].id
 
 policy = jsonencode({
   Version = "2012-10-17"
   Statement = [{
     Effect = "Allow"
     Action = [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents",
       "logs:DescribeLogGroups",
       "logs:DescribeLogStreams"
     ]
     Resource = "*"
   }]
 })
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
 count = var.enable_flow_logs ? 1 : 0
 
 iam_role_arn             = aws_iam_role.flow_logs[0].arn
 log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
 traffic_type             = var.flow_logs_traffic_type
 vpc_id                   = aws_vpc.main.id
 max_aggregation_interval = 60
 
 tags = merge(
   var.tags,
   {
     Name = "${var.name_prefix}-flow-logs"
   }
 )
}

# Optional: S3 Bucket for Flow Logs (alternative to CloudWatch)
resource "aws_s3_bucket" "flow_logs" {
 count = var.enable_flow_logs && var.flow_logs_destination_type == "s3" ? 1 : 0
 
 bucket = "${var.name_prefix}-flow-logs-${data.aws_caller_identity.current.account_id}"
 
 tags = merge(
   var.tags,
   {
     Name = "${var.name_prefix}-flow-logs"
   }
 )
 # Add this lifecycle block to ignore tags that are automatically added by AWS.
  lifecycle {
    ignore_changes = [
      tags_all,
    ]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
 count = var.enable_flow_logs && var.flow_logs_destination_type == "s3" ? 1 : 0
 
 bucket = aws_s3_bucket.flow_logs[0].id
 
 rule {
   id     = "expire-old-logs"
   status = "Enabled"

   filter {
      prefix = ""     # explicitly targets all objects
    }
   
   expiration {
     days = var.flow_logs_retention_days
   }
   
   transition {
     days          = 30
     storage_class = "STANDARD_IA"
   }
   
   transition {
     days          = 60
     storage_class = "GLACIER"
   }
 }
}

# Data source for current account
data "aws_caller_identity" "current" {}