variable "sqs_fifo_arn" {
  description = "The ARN of the main SQS FIFO queue to grant permissions to."
  type        = string
}

variable "sqs_fifo_arn_dlq" {
  description = "The ARN of the SQS FIFO DLQ to grant permissions to."
  type        = string
}

variable "sqs_fifo_name" {
  description = "The name of the main SQS FIFO queue."
  type        = string
}

variable "sqs_fifo_eventbridge_arn_dlq" {
  description = "The ARN of the SQS FIFO DLQ for EventBridge."
  type        = string
}

variable "dynamodb_idemp_arn" {
  description = "The ARN of dynamoDB table for idempotency"
  type        = string
}

variable "lambda_exec_role_name" {
  description = "Name of the global Lambda execution role to attach regional policies to."
  type        = string
}


