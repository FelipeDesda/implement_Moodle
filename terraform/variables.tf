# ==============================================================================
# Variables - Moodle Infrastructure
# ==============================================================================

# ------------------------------------------------------------------------------
# General
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region para provisionar recursos"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nome do ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nome do projeto para tagging"
  type        = string
  default     = "moodle"
}

# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block para subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_a_cidr" {
  description = "CIDR block para subnet privada na AZ A"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_b_cidr" {
  description = "CIDR block para subnet privada na AZ B"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone_a" {
  description = "Availability Zone A"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "Availability Zone B"
  type        = string
  default     = "us-east-1b"
}

# ------------------------------------------------------------------------------
# Compute (EC2)
# ------------------------------------------------------------------------------

variable "ec2_instance_type" {
  description = "Tipo de instância EC2"
  type        = string
  default     = "t3.medium"
}

variable "ec2_key_name" {
  description = "Nome da chave SSH para acesso à EC2"
  type        = string
  default     = "vockey"
}

variable "ssh_allowed_cidr" {
  description = "CIDR permitido para acesso SSH (restrinja ao seu IP)"
  type        = string
  default     = "0.0.0.0/0"
}

# ------------------------------------------------------------------------------
# Database (RDS)
# ------------------------------------------------------------------------------

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "moodle"
}

variable "db_username" {
  description = "Username do banco de dados"
  type        = string
  default     = "moodleuser"
  sensitive   = true
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Storage alocado para RDS em GB"
  type        = number
  default     = 20
}
