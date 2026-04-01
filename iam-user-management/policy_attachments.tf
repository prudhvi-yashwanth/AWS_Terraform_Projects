resource "aws_iam_group_policy_attachment" "attachments" {
  for_each = local.role_to_group

  provider = aws.india

  group      = aws_iam_group.groups[each.value].name
  policy_arn = aws_iam_policy.policies[each.key].arn

  depends_on = [
    aws_iam_group.groups,
    aws_iam_policy.policies
  ]
}