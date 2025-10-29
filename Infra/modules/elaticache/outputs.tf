output "elaticache_address" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "elaticache_port" {
  value = aws_elasticache_replication_group.this.port
}