output "rds_user_name" {
  value = aws_rds_cluster.rds.master_username
}

output "rds_user_password" {
  value = aws_rds_cluster.rds.master_password
}

output "rds_address" {
  value = aws_rds_cluster.rds.endpoint
}

output "rds_port" {
  value = aws_rds_cluster.rds.port
}

output "rds_db_name" {
  value = aws_rds_cluster.rds.database_name
}