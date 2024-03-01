output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "public_route_table_id" {
  value = aws_default_route_table.default.id
}
