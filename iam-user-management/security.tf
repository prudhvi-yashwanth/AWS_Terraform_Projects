# IAM policy document to enforce MFA
data "aws_iam_policy_document" "mfa_enforce" {
  statement {
    sid    = "DenyAllExceptMFA"
    effect = "Deny"

    # Deny all actions except those needed to configure MFA
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

    # Deny if MFA is not present
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

# CloudTrail bucket policy allowing CloudTrail service to write logs
data "aws_iam_policy_document" "cloudtrail_s3_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
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

    # CloudTrail writes logs under AWSLogs/<account_id>/*
    resources = [
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    # Ensure CloudTrail writes with bucket-owner-full-control ACL
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

data "aws_caller_identity" "current" {}

# Attach CloudTrail bucket policy
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  provider = aws.india
  bucket   = aws_s3_bucket.cloudtrail_logs.id
  policy   = data.aws_iam_policy_document.cloudtrail_s3_policy.json
}

# Create MFA enforcement policy
resource "aws_iam_policy" "mfa_enforce_policy" {
  provider    = aws.india
  name        = "enforce-mfa-policy"
  description = "Deny all actions if MFA is not enabled"
  policy      = data.aws_iam_policy_document.mfa_enforce.json

  tags = {
    ManagedBy = "Terraform"
    Security  = "MFA-Enforcement"
  }
}

# Attach MFA enforcement policy to all IAM groups
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

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  provider = aws.india
  bucket   = "prudhvi-cloudtrail-logs-12345"

  force_destroy = true  

  tags = {
    Purpose = "CloudTrailLogs"
  }
}

# CloudTrail configuration
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

# Block public access to CloudTrail bucket
resource "aws_s3_bucket_public_access_block" "cloudtrail_block" {
  provider = aws.india
  bucket   = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
