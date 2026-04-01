# Assign IAM users to groups based on their role
resource "aws_iam_user_group_membership" "user_membership" {
  for_each = local.users
  provider = aws.india

  user = aws_iam_user.users[each.key].name

  # Map the user's role to the correct IAM group
  groups = [
    aws_iam_group.groups[
      local.role_to_group[each.value.role]
    ].name
  ]

  depends_on = [
    aws_iam_user.users,
    aws_iam_group.groups
  ]
}
