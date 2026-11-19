# ==============================================================================
# Database Module - RDS PostgreSQL
# ==============================================================================

# ------------------------------------------------------------------------------
# Security Group - RDS
# ------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group para RDS PostgreSQL - acesso apenas da EC2"
  vpc_id      = var.vpc_id

  # Egress - Restrito (RDS não precisa sair)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }
}

# Regra de ingresso separada para evitar dependência circular
# A regra será criada depois que o EC2 SG existir
resource "aws_security_group_rule" "rds_ingress_from_ec2" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.ec2_security_group_id
  security_group_id        = aws_security_group.rds.id
  description              = "PostgreSQL from EC2"
}

# ------------------------------------------------------------------------------
# DB Subnet Group
# ------------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [var.private_subnet_a_id, var.private_subnet_b_id]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# RDS PostgreSQL Instance
# ------------------------------------------------------------------------------

resource "aws_db_instance" "moodle" {
  identifier     = "${var.project_name}-postgres"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  # Storage
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2  # Auto-scaling até 2x
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Snapshots
  skip_final_snapshot       = true  # Para ambiente de desenvolvimento
  final_snapshot_identifier = "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot     = true

  # Performance Insights (opcional - disponível em db.t3.micro)
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = data.aws_iam_role.rds_monitoring.arn

  # Updates
  auto_minor_version_upgrade = true
  apply_immediately          = false

  # Deletion protection
  deletion_protection = false  # Para ambiente de desenvolvimento

  tags = {
    Name        = "${var.project_name}-postgres"
    Environment = var.environment
    Engine      = "postgres-15"
  }

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }
}

# ------------------------------------------------------------------------------
# Data Source - IAM Role para Enhanced Monitoring
# ------------------------------------------------------------------------------

data "aws_iam_role" "rds_monitoring" {
  name = "LabRole"
}
