# ==============================================================================
# Database Module - Variables
# ==============================================================================

# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "private_subnet_a_id" {
  description = "ID da subnet privada A"
  type        = string
}

variable "private_subnet_b_id" {
  description = "ID da subnet privada B"
  type        = string
}

variable "ec2_security_group_id" {
  description = "ID do Security Group da EC2 (para permitir conexão ao RDS)"
  type        = string
}

# ------------------------------------------------------------------------------
# Database Configuration
# ------------------------------------------------------------------------------

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "db_username" {
  description = "Usuário master do banco de dados"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha do usuário master"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "A senha do banco de dados deve ter no mínimo 8 caracteres."
  }
}

variable "db_allocated_storage" {
  description = "Storage alocado em GB"
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 100
    error_message = "O storage deve estar entre 20 e 100 GB."
  }
}

# ------------------------------------------------------------------------------
# Tags
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}
