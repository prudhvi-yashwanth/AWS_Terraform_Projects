# Expose normalized user map
output "users_map" {
  value = local.users
}

# Map employee IDs to IAM usernames
output "iam_user_names" {
  value = {
    for emp_id, user in aws_iam_user.users :
    emp_id => user.name
  }
}

# Encrypted passwords (PGP encrypted, sensitive output)
output "encrypted_passwords" {
  value = {
    for emp_id, profile in aws_iam_user_login_profile.login_profiles :
    emp_id => profile.encrypted_password
  }
  sensitive = true
}

# IAM group names
output "iam_groups" {
  value = {
    for group_name, group in aws_iam_group.groups :
    group_name => group.name
  }
}

# Map users to their assigned groups
output "user_group_mapping" {
  value = {
    for emp_id, membership in aws_iam_user_group_membership.user_membership :
    emp_id => membership.groups
  }
}

# Policy ARNs by role
output "policy_arns" {
  value = {
    for role, policy in aws_iam_policy.policies :
    role => policy.arn
  }
}

# Map roles to group-policy attachments
output "group_policy_mapping" {
  value = {
    for role, attach in aws_iam_group_policy_attachment.attachments :
    role => {
      group  = attach.group
      policy = attach.policy_arn
    }
  }
}
