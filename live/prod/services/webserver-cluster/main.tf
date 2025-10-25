provider "aws" {
  region = "us-east-2"
}

module "webserver-cluster" {
  source = "../../../../modules/services/webserver-cluster"

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

  enable_autoscaling = true
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