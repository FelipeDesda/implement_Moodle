# ==============================================================================
# Networking Module - VPC, Subnets, Internet Gateway, Route Tables
# ==============================================================================

# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# Internet Gateway
# ------------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# Subnets
# ------------------------------------------------------------------------------

# Subnet pública - EC2 Moodle
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-subnet-public-${var.availability_zone_a}"
    Environment = var.environment
    Type        = "public"
  }
}

# Subnet privada A - RDS primary
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = var.availability_zone_a

  tags = {
    Name        = "${var.project_name}-subnet-private-${var.availability_zone_a}"
    Environment = var.environment
    Type        = "private"
  }
}

# Subnet privada B - RDS subnet group (exigência AWS)
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = var.availability_zone_b

  tags = {
    Name        = "${var.project_name}-subnet-private-${var.availability_zone_b}"
    Environment = var.environment
    Type        = "private"
  }
}

# ------------------------------------------------------------------------------
# Route Table - Public
# ------------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-rtb-public"
    Environment = var.environment
  }
}

# Associa route table à subnet pública
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
