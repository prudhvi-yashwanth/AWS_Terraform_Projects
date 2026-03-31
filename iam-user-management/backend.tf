terraform {
  backend "s3" {
    bucket = "prudhvi-tf-state-unique-12345"
    key    = "iam-users/terraform.tfstate"
    region = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}
