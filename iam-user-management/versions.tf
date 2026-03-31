terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Use latest 5.x version
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
