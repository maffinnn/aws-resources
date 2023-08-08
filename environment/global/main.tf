# ---global/main.tf---

provider "aws" {
  region                   = "ap-southeast-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

terraform {
  backend "s3" {
    bucket  = "terraform-state-govtech-tap"
    key     = "environment/global/global.tfstate"
    region  = "ap-southeast-1"
    profile = "default"
    encrypt = true
  }
}

module "s3" {
  source            = "../../modules/s3"
  bucket_name       = "govtech-tap-ap-southeast-1-elb-access-logs"
  environment       = "prod"
  enable_encryption = true
  enable_versioning = false
  account_id        = "203630641684"
}
