# ==============================================================================
# Main Terraform Configuration - Moodle on AWS
# ==============================================================================
# Este arquivo orquestra a criação da infraestrutura completa do Moodle,
# integrando os módulos de networking, compute e database.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Moodle-Infrastructure"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
    }
  }
}

# ==============================================================================
# Data Sources
# ==============================================================================

# Referencia o LabRole pré-existente no AWS Learn Lab
# Não cria recursos IAM - apenas referencia perfil existente
data "aws_iam_instance_profile" "lab_role" {
  name = "LabInstanceProfile"
}

# Busca a AMI mais recente do Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ==============================================================================
# Módulo de Networking
# ==============================================================================

module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_a_cidr = var.private_subnet_a_cidr
  private_subnet_b_cidr = var.private_subnet_b_cidr
  availability_zone_a  = var.availability_zone_a
  availability_zone_b  = var.availability_zone_b
  environment          = var.environment
  project_name         = var.project_name
}

# ==============================================================================
# Módulo de Database (RDS PostgreSQL)
# ==============================================================================
# Nota: Database é criado primeiro para fornecer o endpoint ao EC2 user_data

module "database" {
  source = "./modules/database"

  # Dependências de rede
  vpc_id                = module.networking.vpc_id
  private_subnet_a_id   = module.networking.private_subnet_a_id
  private_subnet_b_id   = module.networking.private_subnet_b_id
  
  # Configuração do RDS
  db_instance_class     = var.db_instance_class
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  db_allocated_storage  = var.db_allocated_storage
  
  # Tags
  environment           = var.environment
  project_name          = var.project_name

  depends_on = [module.networking]
}

# ==============================================================================
# Módulo de Compute (EC2)
# ==============================================================================

module "compute" {
  source = "./modules/compute"

  # Dependências de rede
  vpc_id            = module.networking.vpc_id
  public_subnet_id  = module.networking.public_subnet_id
  
  # Configuração da instância
  instance_type     = var.ec2_instance_type
  ami_id            = data.aws_ami.amazon_linux_2023.id
  key_name          = var.ec2_key_name
  
  # IAM
  iam_instance_profile = data.aws_iam_instance_profile.lab_role.name
  
  # Configuração do Moodle
  db_host           = module.database.db_address
  db_name           = var.db_name
  db_user           = var.db_username
  db_password       = var.db_password
  moodle_site_url   = "http://localhost"  # Será atualizado pelo container
  
  # Segurança
  ssh_allowed_cidr  = var.ssh_allowed_cidr
  
  # Tags
  environment       = var.environment
  project_name      = var.project_name

  depends_on = [module.networking]
}

# ==============================================================================
# Security Group Rule - Permite conexão EC2 -> RDS
# ==============================================================================
# Criado após ambos os security groups existirem para evitar dependência circular

resource "aws_security_group_rule" "rds_ingress_from_ec2" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.compute.ec2_security_group_id
  security_group_id        = module.database.db_security_group_id
  description              = "PostgreSQL from EC2"
}
