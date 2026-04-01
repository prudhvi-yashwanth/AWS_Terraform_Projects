resource "aws_iam_group" "groups" {
  for_each = toset(values(local.role_to_group))
  provider = aws.india
  name     = each.value
  path     = "/"
}