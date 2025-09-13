resource "aws_secretsmanager_secret" "db-proxy" {
  name = "gj2025-rds-credentials"
}