terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  # region = var.region
  # profile = var.aws_profile
}


data "aws_caller_identity" "current" {} # data.aws_caller_identity.current.account_id

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

### Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "cloud_trail_log_group" {
  name_prefix = "${var.org}-cloudtrail"
}

resource "aws_cloudwatch_log_subscription_filter" "kdf_logfilter" {
  name            = "send_to_kdf"
  role_arn        = aws_iam_role.cloudwatch.arn
  log_group_name  = aws_cloudwatch_log_group.cloud_trail_log_group.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.cloudtrail_stream.arn
  # distribution    = "Random"
}

## Firehose 
resource "aws_kinesis_firehose_delivery_stream" "cloudtrail_stream" {
  name        = "${var.org}-kinesis-firehose-cloud-trail"
  destination = "splunk"

  splunk_configuration {
    hec_endpoint               = var.hec_url
    hec_token                  = var.hec_token
    hec_acknowledgment_timeout = 600
    hec_endpoint_type          = "Raw"
    s3_backup_mode             = "FailedEventsOnly"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = aws_s3_bucket.cloud_trail_errors.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose-to-s3-role-${var.source_service}"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_s3_bucket" "cloud_trail" {
  bucket_prefix = "${var.org}-cloudtrail" 
  force_destroy = true
}

resource "aws_s3_bucket" "cloud_trail_errors" {
  bucket = "${var.org}-kdf-${var.source_service}-errors"
}
data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

### Cloudwatch Role, Policy and attachment
resource "aws_iam_role" "cloudwatch" {
  name               = "CloudWatchToKDF"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume_role_policy.json
  
}

data "aws_iam_policy_document" "cloudwatch_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloud_watch_put_firehose" {
  statement {
    sid = "AllowFirehosePutRecord"
    actions   = ["firehose:PutRecord"]
    resources = [aws_kinesis_firehose_delivery_stream.cloudtrail_stream.arn]
    effect = "Allow"
  }
}
resource "aws_iam_policy" "allow_put_firehose" {
  name        = "AllowPutToFirehose-${var.source_service}"
  description = "Allows putting data to firehose"
  policy      = data.aws_iam_policy_document.cloud_watch_put_firehose.json
}
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = aws_iam_policy.allow_put_firehose.arn
}

### CloudTrail Role, Policy and attachment
resource "aws_iam_role" "cloudtrail" {
  name               = "CloudTrailToCloudWatch"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role_policy.json
}

data "aws_iam_policy_document" "cloudtrail_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloud_trail_to_cloud_watch" {
  statement {
    sid = "AllowCloudTrailPutLogs"
    actions   = ["logs:PutLogEvents","logs:DescribeLogStreams"]
    resources = ["${aws_cloudwatch_log_group.cloud_trail_log_group.arn}:log-stream:${local.aws_account_id}_CloudTrail_*"]
    effect = "Allow"
  }
    statement {
    sid = "AllowCloudTrailCreateLogStream"
    actions   = ["logs:CreateLogStream"]
    resources = [aws_cloudwatch_log_group.cloud_trail_log_group.arn]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "allow_put_logs" {
  name        = "AllowPutToLogs"
  description = "Allows writing from cloudtrial to cloudwatch log groups"
  policy      = data.aws_iam_policy_document.cloud_trail_to_cloud_watch.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_attach" {
  role       = aws_iam_role.cloudtrail.name
  policy_arn = aws_iam_policy.allow_put_logs.arn
}