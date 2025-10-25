provider "aws" {
  region = "us-east-2"
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-stage"
  db_remote_state_bucket = "asan-li-terraform-state"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = "t3.micro"
  server_text = "New server text || 123456"

  min_size           = 1
  max_size           = 5
  enable_autoscaling = false
}

terraform {
  backend "s3" {
    # Укажите здесь имя своей корзины!
    bucket = "asan-li-terraform-state"
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-2"
    # Укажите здесь имя своей таблицы DynamoDB!
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}