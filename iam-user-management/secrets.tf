# Create IAM login profiles for each user
resource "aws_iam_user_login_profile" "login_profiles" {
  for_each = local.users
  provider = aws.india

  user = aws_iam_user.users[each.key].name

  password_length         = 16
  password_reset_required = true

  # Encrypt generated password with PGP public key
  # Note: file() reads the contents of clean_key.txt in this module directory
  pgp_key = file("${path.module}/clean_key.txt")

  depends_on = [
    aws_iam_user.users
  ]
}
