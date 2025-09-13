output "db_proxy_secrets_manager_id" {
  value = aws_secretsmanager_secret.db-proxy.id
}

output "db_proxy_secrets_manager_arn" {
  value = aws_secretsmanager_secret.db-proxy.arn
}