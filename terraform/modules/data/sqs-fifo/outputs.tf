output "queue_arn" {
  value = aws_sqs_queue.main.arn
}

output "queue_name" {
  value = aws_sqs_queue.main.name
}
