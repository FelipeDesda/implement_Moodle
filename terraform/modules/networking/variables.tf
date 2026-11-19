# ==============================================================================
# Networking Module - Variables
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block para subnet pública"
  type        = string
}

variable "private_subnet_a_cidr" {
  description = "CIDR block para subnet privada A"
  type        = string
}

variable "private_subnet_b_cidr" {
  description = "CIDR block para subnet privada B"
  type        = string
}

variable "availability_zone_a" {
  description = "Availability Zone A"
  type        = string
}

variable "availability_zone_b" {
  description = "Availability Zone B"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}
