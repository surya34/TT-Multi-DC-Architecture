output "role_name" {
 value = aws_iam_role.local_role_name.name
}

output "role_arn"  {
 value = aws_iam_role.local_role_name.arn
}
