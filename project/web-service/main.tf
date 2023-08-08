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


module "ec2" {
  source                  = "../../modules/ec2"
  ami_owner               = "137112412989"
  ami_name                = "al2023-ami-2023.1.20230725.0-kernel-6.1-x86_64"
  launch_template_name    = "prod-ecs-ap-southeast-1-lt"
  environment             = "prod"
  instance_type           = "t2.micro"
  iam_instance_profile    = "arn:aws:iam::203630641684:instance-profile/InstanceProfile"
  key_name                = "terraform-access"
  security_group_lt       = "sg-024dd73b3c06df59e"
  instance_name           = "prod-ecs-ap-southeast-1-node"
  user_data               = filebase64("user_data.sh")
  asg_name                = "prod-ecs-ap-southeast-1-asg"
  min_size                = 1
  desired_capacity        = 2
  max_size                = 5
  service_linked_role_arn = "arn:aws:iam::203630641684:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling_0"
  subnet_ids              = ["subnet-0a7c1d91ba320e184", "subnet-0f0f7fb7bce9d1add"]
}


module "ecs-service" {
  source                            = "../../modules/ecs-service"
  ecs_cluster_id                    = "prod-ap-southeast-1-ecs"
  task_family                       = "web-service"
  container_definitions             = file("web-service-cd.json")
  service_name                      = "web-service"
  desired_count                     = 2
  deployment_max                    = 200
  deployment_min                    = 100
  container_name                    = "web-service-container"
  container_port                    = 3000
  target_group_arn                  = "arn:aws:elasticloadbalancing:ap-southeast-1:203630641684:targetgroup/prod-tg/2bb78354790ed49d"
  enable_deployment_circuit_breaker = false
  enable_rollback                   = false
  placement_constraint_type         = "memberOf"
  placement_constraint_expression   = "attribute:ecs.availability-zone in [ap-southeast-1a, ap-southeast-1b]"
  execution_role_arn                = "arn:aws:iam::203630641684:role/ECSExecutionRole"
  task_role_arn                     = "arn:aws:iam::203630641684:role/ECSExecutionRole"
  network_mode                      = "bridge"
  enable_ecs_managed_tags           = true
  propagate_tags                    = "SERVICE"
  enable_execute_command            = false
  health_check_grace_period         = 60
  iam_role                          = "arn:aws:iam::203630641684:role/ECSRole"
}
