variable "cluster_name" {
  description = "An example cluster name in TF"
  type        = string
}

variable "ami" {
  description = "The AMI to run in the cluster"
  type        = string
  default     = "ami-0fb653ca2d3203ac1"
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t3.micro)"
  type        = string

  validation {
    condition     = contains(["t3.micro"], var.instance_type)
    error_message = "Only free tier is allowed: t3.micro"
  }
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1"
  }

  validation {
    condition     = var.min_size <= 10
    error_message = "ASGs must have 10 or fewer instances to keep costs down"
  }
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type        = bool
}

variable "custom_tags" {
  type        = map(string)
  description = "Custom tags to set on the Instances in the ASG"
  default     = {}
}

variable "server_port" {
  description = "An example server port in TF"
  type        = number
  default     = 8080
}

variable "subnet_ids" {
  description = "The subnet IDs to deploy to"
  type        = list(string)
}

# variable "target_group_arns" {
#   description = "The ARNs of ELB target groups in which to register Instances"
#   type        = list(string)
#   default     = []
# }

variable "health_check_type" {
  description = "The type of health check to perform. Must be one of: EC2, ELB."
  type        = string
  default     = "EC2"
}

variable "user_data" {
  description = "The User Data script to run in each Instance at boot"
  type        = string
  default     = null
}

variable "key_pair_name" {
  type        = string
  description = "The name of the key pair to use for the instances"
}