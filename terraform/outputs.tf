# ==============================================================================
# Outputs - Moodle Infrastructure
# ==============================================================================

# ------------------------------------------------------------------------------
# Networking Outputs
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.networking.vpc_id
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = module.networking.public_subnet_id
}

output "private_subnet_a_id" {
  description = "ID da subnet privada A"
  value       = module.networking.private_subnet_a_id
}

output "private_subnet_b_id" {
  description = "ID da subnet privada B"
  value       = module.networking.private_subnet_b_id
}

# ------------------------------------------------------------------------------
# Compute Outputs
# ------------------------------------------------------------------------------

output "ec2_instance_id" {
  description = "ID da instância EC2"
  value       = module.compute.instance_id
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = module.compute.public_ip
}

output "ec2_public_dns" {
  description = "DNS público da instância EC2"
  value       = module.compute.public_dns
}

output "moodle_url" {
  description = "URL de acesso ao Moodle"
  value       = "http://${module.compute.public_dns}"
}

# ------------------------------------------------------------------------------
# Database Outputs
# ------------------------------------------------------------------------------

output "rds_endpoint" {
  description = "Endpoint do RDS PostgreSQL"
  value       = module.database.db_endpoint
}

output "rds_instance_id" {
  description = "ID da instância RDS"
  value       = module.database.db_instance_id
}

output "rds_database_name" {
  description = "Nome do banco de dados"
  value       = module.database.db_name
}

# ------------------------------------------------------------------------------
# Connection Instructions
# ------------------------------------------------------------------------------

output "connection_instructions" {
  description = "Instruções para conectar ao ambiente"
  value = <<-EOT
    
    ========================================
    MOODLE INFRASTRUCTURE - CONNECTION INFO
    ========================================
    
    🌐 Moodle URL:
       http://${module.compute.public_dns}
    
    🔐 SSH Access:
       ssh -i ~/.ssh/${var.ec2_key_name}.pem ec2-user@${module.compute.public_ip}
    
    🗄️  Database Endpoint:
       ${module.database.db_endpoint}
    
    📝 Next Steps:
       1. Aguarde ~5 minutos para o Docker inicializar
       2. Verifique health: ./scripts/health-check.sh ${module.compute.public_dns}
       3. Acesse o Moodle no navegador
    
    ========================================
  EOT
}
