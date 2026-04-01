data "aws_iam_policy_document" "mfa_enforce" {

  statement {
    sid    = "DenyAllExceptMFA"
    effect = "Deny"

    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken"
    ]

    resources = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_s3_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = [aws_s3_bucket.cloudtrail_logs.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}


data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  provider = aws.india

  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_s3_policy.json
}



resource "aws_iam_policy" "mfa_enforce_policy" {
  provider = aws.india

  name        = "enforce-mfa-policy"
  description = "Deny all actions if MFA is not enabled"

  policy = data.aws_iam_policy_document.mfa_enforce.json

  tags = {
    ManagedBy = "Terraform"
    Security  = "MFA-Enforcement"
  }
}

resource "aws_iam_group_policy_attachment" "mfa_attach" {
  for_each = aws_iam_group.groups

  provider = aws.india

  group      = each.value.name
  policy_arn = aws_iam_policy.mfa_enforce_policy.arn

  depends_on = [
    aws_iam_group.groups,
    aws_iam_policy.mfa_enforce_policy
  ]
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  provider = aws.india

  bucket = "prudhvi-cloudtrail-logs-12345"

  tags = {
    Purpose = "CloudTrailLogs"
  }
}


resource "aws_cloudtrail" "main" {
  provider = aws.india

  name           = "iam-audit-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket

  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  depends_on = [
  aws_s3_bucket.cloudtrail_logs,
  aws_s3_bucket_policy.cloudtrail_policy
]
}


resource "aws_s3_bucket_public_access_block" "cloudtrail_block" {
  provider = aws.india

  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

