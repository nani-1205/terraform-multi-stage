# 01-network-infra/outputs.tf

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_name_tag_value" {
  description = "The Name tag value of the created VPC (for lookup)"
  value       = var.vpc_name_tag
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_name_tag_value" {
  description = "The Name tag value of the public subnet (for lookup)"
  value       = var.public_subnet_name_tag
}

output "web_app_sg_id" {
  description = "ID of the Web App Security Group"
  value       = aws_security_group.web_app_sg.id
}

output "web_app_sg_name_tag_value" {
  description = "The Name tag value of the Web App Security Group (for lookup)"
  value       = var.web_app_sg_name_tag
}

output "backend_sg_id" {
  description = "ID of the Backend Security Group"
  value       = aws_security_group.backend_sg.id
}

output "backend_sg_name_tag_value" {
  description = "The Name tag value of the Backend Security Group (for lookup)"
  value       = var.backend_sg_name_tag
}

output "db_sg_id" {
  description = "ID of the Database Security Group"
  value       = aws_security_group.db_sg.id
}

output "db_sg_name_tag_value" {
  description = "The Name tag value of the Database Security Group (for lookup)"
  value       = var.db_sg_name_tag
}

output "web_app_eip_allocation_id" {
  description = "Allocation ID of the Web App EIP"
  value       = aws_eip.web_app_eip.id # This is the allocation_id
}

output "web_app_eip_public_ip" {
  description = "Public IP of the Web App EIP"
  value       = aws_eip.web_app_eip.public_ip
}

output "web_app_eip_name_tag_value" {
  description = "The Name tag value of the Web App EIP (for lookup)"
  value       = var.web_app_eip_name_tag
}