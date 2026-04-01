data "aws_iam_policy_document" "developer" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "ec2:RunInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = ["*"]
  }
}


data "aws_iam_policy_document" "tester" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "s3:ListBucket",
      "s3:GetObject",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "devops" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:*",
      "s3:*",
      "elasticloadbalancing:*",
      "cloudformation:*"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "manager" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
      "aws-portal:ViewBilling",
      "aws-portal:ViewUsage"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "policies" {
  for_each = {
    Developer = data.aws_iam_policy_document.developer.json
    Tester    = data.aws_iam_policy_document.tester.json
    DevOps    = data.aws_iam_policy_document.devops.json
    Manager   = data.aws_iam_policy_document.manager.json
  }

  provider = aws.india

  name        = "${each.key}-policy"
  description = "IAM policy for ${each.key} role"

  policy = each.value

  tags = {
    ManagedBy = "Terraform"
    Project   = "IAM-User-Automation"
    Role      = each.key
  }
}