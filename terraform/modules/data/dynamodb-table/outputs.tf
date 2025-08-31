# In modules/dynamodb_table/outputs.tf

output "table_arn" {
  value = aws_dynamodb_table.idemp.arn
}

output "table_name" {
  value = aws_dynamodb_table.idemp.name
}
