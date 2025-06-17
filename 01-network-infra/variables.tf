# 01-network-infra/variables.tf

variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "me-central-1"
}

variable "project_name" {
  description = "A name prefix for all created networking resources"
  type        = string
  default     = "my-app"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for the public subnet"
  type        = string
  default     = "me-central-1a"
}

variable "my_ip_cidr" {
  description = "Your current public IP CIDR for SSH access to SGs"
  type        = string
  default     = "0.0.0.0/0" # WARNING: Change this to your specific IP/32
}

variable "backend_app_port" {
  description = "Port the backend application listens on"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Port the database listens on"
  type        = number
  default     = 3306
}

variable "vpc_name_tag" {
  description = "Name tag for the VPC (used for lookup)"
  type        = string
  default     = "my-app-vpc"
}

variable "public_subnet_name_tag" {
  description = "Name tag for the Public Subnet (used for lookup)"
  type        = string
  default     = "my-app-public-subnet"
}

variable "web_app_sg_name_tag" {
  description = "Name tag for the Web App Security Group (used for lookup)"
  type        = string
  default     = "my-app-web-app-sg"
}

variable "backend_sg_name_tag" {
  description = "Name tag for the Backend Security Group (used for lookup)"
  type        = string
  default     = "my-app-backend-sg"
}

variable "db_sg_name_tag" {
  description = "Name tag for the Database Security Group (used for lookup)"
  type        = string
  default     = "my-app-db-sg"
}

variable "web_app_eip_name_tag" {
  description = "Name tag for the Web App Elastic IP (used for lookup)"
  type        = string
  default     = "WEB-APP-EIP"
}

variable "sns_topic_name_for_alarms" {
  description = "Name for the SNS topic that will receive CloudWatch alarm notifications."
  type        = string
  default     = "my-app-alarms-topic"
}

variable "sns_topic_name_tag" {
  description = "Name tag for the SNS topic (used for lookup by compute script)"
  type        = string
  default     = "my-app-alarms-sns-topic"
}

variable "alarm_notification_emails" {
  description = "A list of email addresses to subscribe to the SNS alarm topic."
  type        = list(string)
  default     = [
    "prabhakararao.nandigrama@assettl.com",
    "yetukurisaijagan@gmail.com"
  ]
}