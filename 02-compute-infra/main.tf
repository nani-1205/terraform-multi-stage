# 02-compute-infra/main.tf

# --- Data Sources to look up existing network resources ---
data "aws_vpc" "selected_vpc" {
  tags = {
    Name = var.vpc_name_tag_to_lookup
  }
}

data "aws_subnet" "selected_public_subnet" {
  vpc_id = data.aws_vpc.selected_vpc.id
  tags = {
    Name = var.public_subnet_name_tag_to_lookup
  }
  # filter { # Alternative if tag is not unique enough within VPC
  #   name   = "tag:Name"
  #   values = [var.public_subnet_name_tag_to_lookup]
  # }
  # filter {
  #   name   = "vpc-id"
  #   values = [data.aws_vpc.selected_vpc.id]
  # }
}

data "aws_security_group" "web_app_sg" {
  name   = var.web_app_sg_name_tag_to_lookup # Assumes SG name matches the tag
  vpc_id = data.aws_vpc.selected_vpc.id
  # tags = { # Alternative lookup by tag if name is not reliable
  #   Name = var.web_app_sg_name_tag_to_lookup
  # }
}

data "aws_security_group" "backend_sg" {
  name   = var.backend_sg_name_tag_to_lookup
  vpc_id = data.aws_vpc.selected_vpc.id
}

data "aws_security_group" "db_sg" {
  name   = var.db_sg_name_tag_to_lookup
  vpc_id = data.aws_vpc.selected_vpc.id
}

data "aws_eip" "web_app_eip" {
  tags = {
    Name = var.web_app_eip_name_tag_to_lookup
  }
}

# --- EC2 Instances ---
resource "aws_instance" "web_app" {
  ami                          = var.ami_id
  instance_type                = var.web_app_instance_type
  key_name                     = var.key_pair_name
  subnet_id                    = data.aws_subnet.selected_public_subnet.id
  vpc_security_group_ids       = [data.aws_security_group.web_app_sg.id]
  associate_public_ip_address  = false # EIP will be associated
  root_block_device {
    volume_size           = 100
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = { Name = "WEB-APP", Tier = "WebApp" }
}

resource "aws_eip_association" "web_app_eip_assoc" {
  instance_id   = aws_instance.web_app.id
  allocation_id = data.aws_eip.web_app_eip.id # Use allocation_id (which is .id from data source)
}

resource "aws_instance" "backend" {
  ami                          = var.ami_id
  instance_type                = var.backend_instance_type
  key_name                     = var.key_pair_name
  subnet_id                    = data.aws_subnet.selected_public_subnet.id
  vpc_security_group_ids       = [data.aws_security_group.backend_sg.id]
  # associate_public_ip_address = true # Implicit from subnet setting
  root_block_device {
    volume_size           = 100
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = { Name = "BACKEND", Tier = "Backend" }
}

resource "aws_instance" "database" {
  ami                          = var.ami_id
  instance_type                = var.db_instance_type
  key_name                     = var.key_pair_name
  subnet_id                    = data.aws_subnet.selected_public_subnet.id
  vpc_security_group_ids       = [data.aws_security_group.db_sg.id]
  # associate_public_ip_address = true # Implicit from subnet setting
  root_block_device {
    volume_size           = 150
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = { Name = "DATABASE", Tier = "Database" }
}