output "users_map" {
  value = local.users
}

output "iam_user_names" {
  value = {
    for emp_id, user in aws_iam_user.users :
    emp_id => user.name
  }
}

output "encrypted_passwords" {
  value = {
    for emp_id, profile in aws_iam_user_login_profile.login_profiles :
    emp_id => profile.encrypted_password
  }

  sensitive = true
}

output "iam_groups" {
  value = {
    for group_name, group in aws_iam_group.groups :
    group_name => group.name
  }
}