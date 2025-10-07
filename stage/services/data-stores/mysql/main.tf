provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-example-db"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = "example_database"

  username = var.db_username
  password = var.db_password
}

terraform {
  backend "s3" {
    # Укажите здесь имя своей корзины!
    bucket = "asan-li-terraform-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
    # Укажите здесь имя своей таблицы DynamoDB!
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}