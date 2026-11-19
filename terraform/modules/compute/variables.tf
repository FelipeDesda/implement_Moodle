# ==============================================================================
# Compute Module - Variables
# ==============================================================================

# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "ID da subnet pública"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR permitido para acesso SSH"
  type        = string
}

# ------------------------------------------------------------------------------
# EC2 Instance
# ------------------------------------------------------------------------------

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
}

variable "ami_id" {
  description = "ID da AMI"
  type        = string
}

variable "key_name" {
  description = "Nome da chave SSH"
  type        = string
}

variable "iam_instance_profile" {
  description = "Nome do IAM instance profile"
  type        = string
}

# ------------------------------------------------------------------------------
# Moodle Configuration
# ------------------------------------------------------------------------------

variable "db_host" {
  description = "Endpoint do banco de dados"
  type        = string
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "db_user" {
  description = "Usuário do banco de dados"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}

variable "moodle_site_url" {
  description = "URL do site Moodle"
  type        = string
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
