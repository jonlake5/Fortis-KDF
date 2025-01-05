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
#  region = var.region
#  profile = var.aws_profile
}



## Create Event Filters for Security Hub
resource "aws_cloudwatch_event_rule" "security_hub" {
  name        = "send-${var.source_service}-splunk"
  description = "Capture event and send to splunk"
#   role_arn = aws_iam_role.events_role.arn
  event_pattern = jsonencode({
    source = [
      "aws.securityhub"
    ]
  })
}

resource "aws_cloudwatch_event_target" "firehose" {
  rule      = aws_cloudwatch_event_rule.security_hub.name
  # target_id = "SendToADF"
  arn       = aws_kinesis_firehose_delivery_stream.security-hub_stream.arn
  role_arn = aws_iam_role.events_role.arn
}



## Firehose 
resource "aws_kinesis_firehose_delivery_stream" "security-hub_stream" {
  name        = "${var.org}-kinesis-firehose-${var.source_service}"
  destination = "splunk"

  splunk_configuration {
    hec_endpoint               = var.hec_url
    hec_token                  = var.hec_token
    hec_acknowledgment_timeout = 600
    hec_endpoint_type          = "Raw"
    s3_backup_mode             = "FailedEventsOnly"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = aws_s3_bucket.security-hub.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_to_s3_role_${var.source_service}"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_s3_bucket" "security-hub" {
  bucket = "${var.org}-kdf-${var.source_service}-errors" 
  force_destroy = true
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


### Events Role
resource "aws_iam_role" "events_role" {
  name               = "${var.source_service}-${var.dest_service}_to_firehose"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
}

data "aws_iam_policy_document" "events_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "events_put_firehose" {
  statement {
    sid = "AllowFirehosePutRecord"
    actions   = ["firehose:PutRecord"]
    resources = [aws_kinesis_firehose_delivery_stream.security-hub_stream.arn]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "allow_put_firehose" {
  name        = "Allow${var.dest_service}PutToFirehose-${var.source_service}"
  description = "Allows putting data to firehose"
  policy      = data.aws_iam_policy_document.events_put_firehose.json
}


resource "aws_iam_role_policy_attachment" "events_role_policy" {
    role = aws_iam_role.events_role.name
    policy_arn = aws_iam_policy.allow_put_firehose.arn
}