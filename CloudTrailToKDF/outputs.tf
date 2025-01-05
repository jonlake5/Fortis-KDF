output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.cloud_trail_log_group.name
}

output "cloudwatch_role_name" {
    value = aws_iam_role.cloudwatch.name
}

output "cloudtrail_role_name" {
  value = aws_iam_role.cloudtrail.name
}