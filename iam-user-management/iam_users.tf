resource "aws_iam_user" "users" {
  for_each = local.users
  provider = aws.india
  name     = each.value.username

  path = "/"

  # Force destroy ensures cleanup during terraform destroy
  force_destroy = true

  tags = local.common_tags[each.key]
}