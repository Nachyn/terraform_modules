provider "aws" {
  region = "us-east-2"
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-prod"
  db_remote_state_bucket = "asan-li-terraform-state"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 5

  custom_tags = {
    Owner     = "team-foo"
    ManagedBy = "Terraform"
  }
}

terraform {
  backend "s3" {
    # Укажите здесь имя своей корзины!
    bucket = "asan-li-terraform-state"
    key    = "prod/services/webserver-cluster/terraform.tfstate"
    region = "us-east-2"
    # Укажите здесь имя своей таблицы DynamoDB!
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 1
  max_size              = 5
  desired_capacity      = 2
  recurrence            = "0 9 * * *"

  autoscaling_group_name = module.webserver-cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 1
  max_size              = 5
  desired_capacity      = 1
  recurrence            = "0 17 * * *"

  autoscaling_group_name = module.webserver-cluster.asg_name
}