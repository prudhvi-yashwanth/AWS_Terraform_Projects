provider "aws" {
  alias  = "us"
  region = "us-east-1"
}

provider "aws" {
  alias  = "uk"
  region = "eu-west-2"
}

provider "aws" {
  alias  = "india"
  region = "ap-south-1"
}