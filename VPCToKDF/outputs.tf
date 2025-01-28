output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.security-hub_stream.arn
}

output "firehose_name" {
  value = aws_kinesis_firehose_delivery_stream.security-hub_stream.name
}

output "vpc_role_name" {
  value = aws_iam_role.firehose_role.name
}

