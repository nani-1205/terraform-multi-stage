# 01-network-infra/main.tf

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.vpc_name_tag }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" } # Tagged for easier identification
}

# --- Public Subnet ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true # Important for instances needing public IPs without EIPs
  tags                    = { Name = var.public_subnet_name_tag }
}

# --- Public Route Table ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

# --- Public Route Table Association ---
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Web App Security Group ---
resource "aws_security_group" "web_app_sg" {
  name        = var.web_app_sg_name_tag # Using the tag value also as SG name for easier lookup
  description = "Allow HTTP, HTTPS, and SSH for Web App"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "SSH from My IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = var.web_app_sg_name_tag }
}

# --- Backend Security Group ---
resource "aws_security_group" "backend_sg" {
  name        = var.backend_sg_name_tag
  description = "Allow App port from Web App SG and SSH"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "SSH from My IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description     = "App port from Web App SG"
    from_port       = var.backend_app_port
    to_port         = var.backend_app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web_app_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = var.backend_sg_name_tag }
}

# --- Database Security Group ---
resource "aws_security_group" "db_sg" {
  name        = var.db_sg_name_tag
  description = "Allow DB port from Backend SG and SSH"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "SSH from My IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description     = "Database port from Backend SG"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }
  # Optional: Direct DB access from your IP (use with caution)
  # ingress {
  #   description = "Database port from My IP (direct admin)"
  #   from_port   = var.db_port
  #   to_port     = var.db_port
  #   protocol    = "tcp"
  #   cidr_blocks = [var.my_ip_cidr]
  # }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = var.db_sg_name_tag }
}

# --- Elastic IP for WEB-APP ---
resource "aws_eip" "web_app_eip" { # Renamed from web_app_new_eip for clarity
  tags = { Name = var.web_app_eip_name_tag }
}