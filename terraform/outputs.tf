output "application_url" {
  description = "Access your application here"
  value       = "http://${aws_lb.app_lb.dns_name}"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.restaurants.name
}