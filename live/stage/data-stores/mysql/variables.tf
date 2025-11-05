variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
  default     = "password"
}

variable "db_name" {
  description = "The name to use for the database"
  type        = string
  default     = "db_name_1"
}
