# 02-compute-infra/outputs.tf

output "web_app_instance_id" {
  description = "ID of the WEB-APP EC2 instance"
  value       = aws_instance.web_app.id
}

output "web_app_public_ip_from_eip" {
  description = "Public IP of the WEB-APP instance (from associated EIP)"
  value       = data.aws_eip.web_app_eip.public_ip # Accessing the EIP's public_ip via data source
}

output "web_app_private_ip" {
  description = "Private IP of the WEB-APP EC2 instance"
  value       = aws_instance.web_app.private_ip
}

output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = aws_instance.backend.id
}

output "backend_public_ip" {
  description = "Public IP of the backend EC2 instance"
  value       = aws_instance.backend.public_ip
}

output "backend_private_ip" {
  description = "Private IP of the backend EC2 instance"
  value       = aws_instance.backend.private_ip
}

output "database_instance_id" {
  description = "ID of the Database EC2 instance"
  value       = aws_instance.database.id
}

output "database_public_ip" {
  description = "Public IP of the Database EC2 instance"
  value       = aws_instance.database.public_ip
}

output "database_private_ip" {
  description = "Private IP of the Database EC2 instance"
  value       = aws_instance.database.private_ip
}