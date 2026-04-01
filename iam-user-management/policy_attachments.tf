# Attach IAM policies to groups based on role-to-group mapping
resource "aws_iam_group_policy_attachment" "attachments" {
  for_each = local.role_to_group
  provider = aws.india

  # Look up the group by value (e.g., "dev-group") and attach the policy for the role (e.g., "Developer")
  group      = aws_iam_group.groups[each.value].name
  policy_arn = aws_iam_policy.policies[each.key].arn

  depends_on = [
    aws_iam_group.groups,
    aws_iam_policy.policies
  ]
}
