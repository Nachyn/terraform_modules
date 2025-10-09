variable "cluster_name" {
  description = "An example cluster name in TF"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The S3 bucket where the remote state of the DB is stored"
  type        = string
}

variable "db_remote_state_key" {
  description = "The S3 key where the remote state of the DB is stored"
  type        = string
}

variable "server_port" {
  description = "An example server port in TF"
  type        = number
  default     = 8080
}

variable "instance_type" {
 description = "The type of EC2 Instances to run (e.g. t2.micro)"
 type = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}
variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}