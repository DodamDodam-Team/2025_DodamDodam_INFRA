output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "public_subnet_ids" {
  value = [for name in var.public_subnet_names : aws_subnet.public[name].id]
}

output "private_subnet_ids" {
  value = [for name in var.private_subnet_names : aws_subnet.private[name].id]
}

output "protect_subnet_ids" {
  value = [for name in var.protect_subnet_names : aws_subnet.protect[name].id]
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  value = [for rt in aws_route_table.private : rt.id]
}

output "protected_route_table_id" {
  value = aws_route_table.protect.id
}