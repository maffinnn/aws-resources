# --- prod/ap-southeast-1/main.tf ---
provider "aws" {
  region                   = "ap-southeast-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

data "terraform_remote_state" "Global" {
  backend = "s3"

  config = {
    bucket = "terraform-state-govtech-tap"
    key    = "environment/global/global.tfstate"
    region = "ap-southeast-1"
  }
}

module "networking" {
  source                     = "../../modules/networking"
  environment                = "prod"
  vpc_cidr                   = "10.19.0.0/16"
  vpc_name                   = "prod-ap-southeast-1-vpc"
  gw_name                    = "prod-ap-southeast-1-gw"
  nat_eip_name               = "prod-ap-southeast-1-nat-eip"
  nat_gateway_name           = "prod-ap-southeast-1-nat-gw"
  public_subnet_cidr_blocks  = ["10.19.1.0/24", "10.19.2.0/24"]
  private_subnet_cidr_blocks = ["10.19.3.0/24", "10.19.4.0/24"]
  availability_zones         = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnet_name_prefix  = "public-subnet-prod"
  private_subnet_name_prefix = "private-subnet-prod"
  public_rt_name             = "public-rt-prod"
  private_rt_name            = "private-rt-prod"
  sg_name                    = "prod-ap-southeast-1-sg"
}


module "elb" {
  source                = "../../modules/elb"
  environment           = "prod"
  alb_name              = "prod-alb"
  public_subnets        = module.networking.public_subnet_ids
  alb_sg                = module.networking.sg_id
  listener_port         = 80
  vpc_id                = module.networking.vpc_id
  tg_name               = "prod-tg"
  tg_port               = 80
  target_type           = "instance"
  healthy_threshold     = 2
  unhealthy_threshold   = 2
  health_check_interval = 30
  health_check_path     = "/health"
  health_check_timeout  = 5
}
