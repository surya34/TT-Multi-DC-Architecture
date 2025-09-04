resource "aws_cloudwatch_event_rule" "s3_acl" {
name = var.name
description = "Detect object-level ACL changes"
event_pattern = jsonencode({
 source = ["aws.s3"],
 detail_type = ["Object ACL Updated", "Object Created"],
 })
}
