locals {
  dlq_name = coalesce(var.dlq_name, "${var.name}-dlq")
}

resource "aws_sqs_queue" "dlq" {
  name                        = "${local.dlq_name}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  kms_master_key_id           = var.kms_key_arn
  tags                        = var.tags
}

resource "aws_sqs_queue" "main" {
  name                        = "${var.name}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = var.visibility_timeout_secs
  kms_master_key_id           = var.kms_key_arn
  fifo_throughput_limit       = var.fifo_throughput_limit
  deduplication_scope         = var.dedup_scope

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = var.tags
}
