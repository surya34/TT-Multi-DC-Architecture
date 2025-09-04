output "queue_arn" {
  value = aws_sqs_queue.main.arn
}

output "queue_name" {
  value = aws_sqs_queue.main.name
}

output "queue_arn_dlq" {
  value = aws_sqs_queue.dlq.arn
}

output "queue_event_bridge_arn_dlq" {
  value = aws_sqs_queue.eventbridge_dlq.arn
}
