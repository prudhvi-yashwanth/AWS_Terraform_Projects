output "users_map" {
  value = local.users
}

output "iam_user_names" {
  value = {
    for emp_id, user in aws_iam_user.users :
    emp_id => user.name
  }
}