locals {
  # Step 1: Read CSV
  raw_users = csvdecode(file("${path.module}/users.csv"))

  # Step 2: Normalize + validate fields
  normalized_users = [
    for u in local.raw_users : {
      employee_id = trimspace(u.employee_id)
      first_name  = trimspace(u.first_name)
      last_name   = trimspace(u.last_name)
      role        = trimspace(u.role)
      department  = trimspace(u.department)

      # Derived fields
      username = lower("${trimspace(u.first_name)}.${trimspace(u.last_name)}")
    }
  ]

  # Step 3: Convert to MAP using employee_id as key (stable identity)
  users = {
    for u in local.normalized_users :
    u.employee_id => u
  }

  # Step 4: Extract employee IDs
  employee_ids = [for u in local.normalized_users : u.employee_id]

  # Step 5: Group IDs (clean duplicate detection)
  grouped_employee_ids = {
    for id in local.employee_ids :
    id => true...
  }

  # Step 6: Detect duplicates
  duplicate_employee_ids = toset([
    for id, group in local.grouped_employee_ids : id if length(group) > 1
  ])
}

# Hard fail if duplicates exist
locals {
  _validate_unique_ids = (
    length(local.duplicate_employee_ids) == 0 ?
    true :
    error("Duplicate employee_id(s) found in users.csv: ${join(", ", local.duplicate_employee_ids)}")
  )
}

locals {

  # Common tag builder (DRY approach)
  common_tags = {
    for emp_id, user in local.users :
    emp_id => {
      EmployeeID = emp_id
      FullName   = "${user.first_name} ${user.last_name}"
      FirstName  = user.first_name
      LastName   = user.last_name
      Role       = user.role
      Department = user.department
      ManagedBy  = "Terraform"
      Project    = "IAM-User-Automation"
    }
  }
}

locals {
  role_to_group = {
    Developer = "dev-group"
    Tester    = "testing-group"
    DevOps    = "operations-group"
    Manager   = "management-group"
  }
}


locals {
  invalid_roles = toset([
    for u in local.users :
    u.role if !contains(keys(local.role_to_group), u.role)
  ])
}

locals {
  _validate_roles = (
    length(local.invalid_roles) == 0 ?
    true :
    error("Invalid role(s) found in users.csv: ${join(", ", local.invalid_roles)}")
  )
}

locals {
  # Read the raw file
  raw_key = file("${path.module}/public_key.asc")

  # Remove the BEGIN and END markers, and strip all whitespace (newlines, spaces)
  pgp_key_base64 = replace(
    replace(
      replace(
        local.raw_key,
        "-----BEGIN PGP PUBLIC KEY BLOCK-----", ""
      ),
      "-----END PGP PUBLIC KEY BLOCK-----", ""
    ),
    "/\\s/", ""   # Remove all whitespace (including newlines)
  )
}