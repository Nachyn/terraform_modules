variable "name" {
  description = "The name of the Kubernetes application"
  type        = string
}

variable "image" {
  description = "The Docker image to run"
  type        = string
}

variable "container_port" {
  description = "The port the Docker image listens on"
  type        = number
}

variable "replicas" {
  description = "How many replicas to run"
  type        = number
  default     = 1
}

variable "env_vars" {
  description = "Environment variables to set for the app"
  type        = map(string)
  default     = {}
}