# ==============================================================================
# Database Module - Outputs
# ==============================================================================

output "db_instance_id" {
  description = "ID da instância RDS"
  value       = aws_db_instance.moodle.id
}

output "db_endpoint" {
  description = "Endpoint de conexão do RDS (host:port)"
  value       = aws_db_instance.moodle.endpoint
}

output "db_address" {
  description = "Endereço do RDS (sem porta)"
  value       = aws_db_instance.moodle.address
}

output "db_port" {
  description = "Porta do RDS"
  value       = aws_db_instance.moodle.port
}

output "db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.moodle.db_name
}

output "db_arn" {
  description = "ARN da instância RDS"
  value       = aws_db_instance.moodle.arn
}

output "db_security_group_id" {
  description = "ID do Security Group do RDS"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Nome do DB Subnet Group"
  value       = aws_db_subnet_group.main.name
}
