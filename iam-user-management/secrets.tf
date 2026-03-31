# -------------------------------------------------------------------
# Generate random passwords for each IAM user
# -------------------------------------------------------------------
resource "random_password" "user_passwords" {
  for_each         = local.users
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}<>?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# -------------------------------------------------------------------
# Create a Secrets Manager secret for each IAM user
# -------------------------------------------------------------------
resource "aws_secretsmanager_secret" "user_secrets" {
  for_each    = local.users
  provider    = aws.india
  name        = "iam-user/${each.key}/credentials" # Secret name includes employee_id
  description = "Login credentials for IAM user ${each.value.username}"
  tags        = local.common_tags[each.key]
}

# -------------------------------------------------------------------
# Store the actual secret values (username + password) in Secrets Manager
# -------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "user_secret_values" {
  for_each  = local.users
  secret_id = aws_secretsmanager_secret.user_secrets[each.key].id
  secret_string = jsonencode({
    username = each.value.username
    password = random_password.user_passwords[each.key].result
  })
  depends_on = [
    aws_secretsmanager_secret.user_secrets # Ensure secret exists before version
  ]
}

