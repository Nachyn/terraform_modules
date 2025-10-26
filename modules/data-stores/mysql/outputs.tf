output "address" {
  value       = aws_db_instance.example.address
  description = "The address of the MySQL instance"
}

output "port" {
  value       = aws_db_instance.example.port
  description = "The port of the MySQL instance"
}

output "arn" {
  value       = aws_db_instance.example.arn
  description = "The ARN of the RDS instance"
}