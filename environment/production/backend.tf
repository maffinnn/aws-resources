terraform {
  backend "s3" {
    bucket  = "terraform-state-govtech-tap"
    key     = "environment/production/production.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }
}
