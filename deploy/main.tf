terraform {
  backend "s3" {
    bucket = "terraform-state-ops-reference"
    region = "us-east-1"
    key = "state.tf"
  }
}

