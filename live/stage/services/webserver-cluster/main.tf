terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# default
provider "aws" {
  region = "us-east-2"
}

provider "aws" {
  region = "us-east-2"
  alias  = "region_1"
}

provider "aws" {
  region = "us-west-1"
  alias  = "region_2"
}

data "aws_region" "region_1" {
  provider = aws.region_1
}

data "aws_region" "region_2" {
  provider = aws.region_2
}

data "aws_ami" "ubuntu_region_1" {
  provider = aws.region_1

  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "aws_ami" "ubuntu_region_2" {
  provider = aws.region_2

  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "aws_instance_region_1" {
  provider = aws.region_1

  ami = data.aws_ami.ubuntu_region_1.id # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t3.micro"
}

resource "aws_instance" "aws_instance_region_2" {
  provider = aws.region_2

  ami = data.aws_ami.ubuntu_region_2.id
  instance_type = "t3.micro"
}

output "region_1" {
  value       = data.aws_region.region_1.id
  description = "The name of the first AWS region."
}

output "region_2" {
  value       = data.aws_region.region_2.id
  description = "The name of the second AWS region."
}

output "instance_region_1_az" {
  value = aws_instance.aws_instance_region_1.availability_zone
}

output "instance_region_2_az" {
  value = aws_instance.aws_instance_region_2.availability_zone
}

# module "webserver-cluster" {
#   source = "../../../../modules/services/webserver-cluster"

#   cluster_name           = "webservers-stage"
#   db_remote_state_bucket = "asan-li-terraform-state"
#   db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

#   ami           = "ami-0fb653ca2d3203ac1"
#   instance_type = "t3.micro"
#   server_text   = "New server text || 123456"

#   min_size           = 1
#   max_size           = 5
#   enable_autoscaling = false
# }

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