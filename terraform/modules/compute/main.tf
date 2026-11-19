# ==============================================================================
# Compute Module - EC2 Instance for Moodle
# ==============================================================================

# ------------------------------------------------------------------------------
# Security Group - EC2
# ------------------------------------------------------------------------------

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group para instancia EC2 Moodle"
  vpc_id      = var.vpc_id

  # Regras de entrada
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # Regras de saída - Irrestrito (permite acesso RDS, Docker Hub, etc)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# User Data Script
# ------------------------------------------------------------------------------

locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    db_host         = var.db_host
    db_name         = var.db_name
    db_user         = var.db_user
    db_password     = var.db_password
    moodle_site_url = var.moodle_site_url
  })
}

# ------------------------------------------------------------------------------
# EC2 Instance
# ------------------------------------------------------------------------------

resource "aws_instance" "moodle" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = var.iam_instance_profile

  user_data = local.user_data

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.project_name}-ec2-moodle"
    Environment = var.environment
    Role        = "moodle-server"
  }
}
