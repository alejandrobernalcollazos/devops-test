output "db_endpoint" {
  value = aws_db_instance.mariadb.endpoint
}

output "db_arn" {
  value = aws_db_instance.mariadb.arn
}