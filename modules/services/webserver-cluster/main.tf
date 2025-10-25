locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
}

# resource "aws_security_group" "alb" {
#   name = "${var.cluster_name}-alb"

#   ingress {
#     from_port   = local.http_port
#     to_port     = local.http_port
#     protocol    = local.tcp_protocol
#     cidr_blocks = local.all_ips
#   }
#   egress {
#     from_port   = local.any_port
#     to_port     = local.any_port
#     protocol    = local.any_protocol
#     cidr_blocks = local.all_ips
#   }
# }

resource "aws_launch_template" "example" {
  image_id      = var.ami
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance.id]
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    server_text = var.server_text
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port,
  }))

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_autoscaling_group" "example" {
  name = var.cluster_name
  launch_template {
    id      = aws_launch_template.example.id
    version = aws_launch_template.example.latest_version
  }
  vpc_zone_identifier = data.aws_subnets.default.ids


  # target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "EC2"

  min_size = var.min_size
  max_size = var.max_size

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ags-example"
    propagate_at_launch = true
  }

  # dynamic "tag" {
  #   for_each = var.custom_tags
  #   content {
  #     key                 = tag.key
  #     value               = tag.value
  #     propagate_at_launch = true
  #   }
  # }

  dynamic "tag" {
    for_each = {
      for key, value in var.custom_tags : key => value if key != ""
    }

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 1
  max_size              = 5
  desired_capacity      = 2
  recurrence            = "0 9 * * *"

  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name = "scale-in-at-night"
  min_size              = 1
  max_size              = 5
  desired_capacity      = 1
  recurrence            = "0 17 * * *"

  autoscaling_group_name = aws_autoscaling_group.example.name
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}

output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}

# resource "aws_lb" "example" {
#   name               = "${var.cluster_name}-asg-example"
#   load_balancer_type = "application"
#   subnets            = data.aws_subnets.default.ids
#   security_groups    = [aws_security_group.alb.id]
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.example.arn
#   port              = local.http_port
#   protocol          = "HTTP"

#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       message_body = "Hello, 404!"
#       status_code  = "404"
#     }
#   }
# }

# resource "aws_lb_target_group" "asg" {
#   name     = "{var.cluster_name}-example"
#   port     = var.server_port
#   protocol = "HTTP"
#   vpc_id   = data.aws_vpc.default.id

#   health_check {
#     path                = "/"
#     protocol            = "HTTP"
#     matcher             = "200"
#     interval            = 15
#     timeout             = 3
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#   }
# }