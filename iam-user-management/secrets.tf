resource "aws_iam_user_login_profile" "login_profiles" {
  for_each = local.users

  provider = aws.india

  user = aws_iam_user.users[each.key].name

  password_length         = 16
  password_reset_required = true

  # Optional but recommended
  pgp_key = filebase64("${path.module}/public_key.asc")

  depends_on = [
    aws_iam_user.users
  ]
}