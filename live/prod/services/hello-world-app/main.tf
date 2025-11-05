terraform {
  required_version = ">= 1.13, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "asan-li-terraform-state"
    key    = "prod/services/hello-world-app/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

module "hello_world_app" {
  source = "git::https://github.com/Nachyn/terraform_modules.git//modules/services/hello-world-app?ref=v0.0.6"

  server_text = "Hello, World from Prod!"

  environment            = var.environment
  db_remote_state_bucket = "asan-li-terraform-state"
  db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"

  instance_type      = "t3.micro"
  min_size           = 2
  max_size           = 2
  enable_autoscaling = true
  ami                = data.aws_ami.ubuntu.id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}