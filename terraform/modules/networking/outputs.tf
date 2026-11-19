# ==============================================================================
# Networking Module - Outputs
# ==============================================================================

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block da VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = aws_subnet.public.id
}

output "private_subnet_a_id" {
  description = "ID da subnet privada A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "ID da subnet privada B"
  value       = aws_subnet.private_b.id
}

output "public_route_table_id" {
  description = "ID da route table pública"
  value       = aws_route_table.public.id
}
